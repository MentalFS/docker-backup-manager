FROM debian:stable-20240423-slim AS build

# Setup
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt update; \
    apt -y install --no-install-recommends cron \
        bzip2 gettext-base gpg lzma openssh-client rsync xz-utils \
        backup-manager; \
    apt clean; rm -rf /var/lib/apt/lists/* /var/log/*

RUN set -eux; \
    test -f /usr/share/perl5/BackupManager/Logger.pm \
    && sed -i "/^\\s*setlogsock('unix');\\s*$/s/^/#/" /usr/share/perl5/BackupManager/Logger.pm; \
    mv /etc/backup-manager.conf /etc/backup-manager.conf.orig; \
    chown backup:backup /var/backups; \
    chmod g+rw /var/backups

COPY bin/start /
COPY bin/cron /
COPY bin/backup-manager /
COPY bin/backup-check /
COPY etc/backup-manager.conf /etc/
ENTRYPOINT ["/start"]
CMD ["/cron"]

# Configuration
ENV BM_CRON="0 3 * * *" \
    BM_REPOSITORY_USER="root" \
    BM_REPOSITORY_GROUP="root" \
    BM_REPOSITORY_RECURSIVEPURGE="false" \
    BM_ARCHIVE_PURGEDUPS="true" \
    BM_ARCHIVE_PREFIX="DOCKER" \
    BM_ARCHIVE_STRICTPURGE="true" \
    BM_ARCHIVE_METHOD="tarball-incremental" \
    BM_ARCHIVE_TTL="14" \
    BM_ENCRYPTION_METHOD="false" \
    BM_ENCRYPTION_RECIPIENT="" \
    BM_TARBALL_NAMEFORMAT="long" \
    BM_TARBALL_FILETYPE="tar.gz" \
    BM_TARBALL_DIRECTORIES="/VOLUME/*" \
    BM_TARBALL_BLACKLIST="" \
    BM_TARBALLINC_MASTERDATETYPE="weekly" \
    BM_TARBALLINC_MASTERDATEVALUE="1" \
    BM_UPLOAD_METHOD="none" \
    BM_UPLOAD_SSH_USER="" \
    BM_UPLOAD_SSH_KEY="/etc/ssh/id_rsa" \
    BM_UPLOAD_SSH_HOSTS="" \
    BM_UPLOAD_SSH_PORT="" \
    BM_UPLOAD_SSH_DESTINATION="" \
    BM_UPLOAD_SSH_PURGE="true" \
    BM_UPLOAD_SSH_TTL="" \
    BM_UPLOAD_SSHGPG_RECIPIENT="" \
    BM_UPLOAD_RSYNC_DIRECTORIES="/var/archives/" \
    BM_UPLOAD_RSYNC_DESTINATION="" \
    BM_UPLOAD_RSYNC_HOSTS="" \
    BM_UPLOAD_RSYNC_BLACKLIST="" \
    BM_UPLOAD_RSYNC_BANDWIDTH_LIMIT="" \
    GNUPGHOME="/etc/gnupg" \
    LANG=C.UTF-8 \
    TZ=Europe/Berlin


# Tests
FROM build AS test-base
RUN set -eux; \
	test -e /root; test -r /root; \
    chmod a+rX /root -R; \
    ls -lha /root; \
    stat -c "%n %U %G %a" /etc/backup-manager.conf; \
    stat -c "%a" /etc/backup-manager.conf | egrep '^644$'; \
    mkdir -p /var/archives/.temp
ENV BM_CRON=@reboot \
    BM_ARCHIVE_PREFIX="ROOT" \
    BM_REPOSITORY_USER="1000" \
    BM_REPOSITORY_GROUP="1000"
RUN sed 's:^exec \(.*\):timeout 5 \1 || echo OK:' /start -i

FROM test-base AS test-success
ENV BM_TARBALL_DIRECTORIES="/root"
RUN ["/start", "/cron"]
RUN set -eux; echo Test successful backup; \
    find /var/archives/.temp/ -type f -exec cat {} + ; \
    ls -lhRn /var/archives /var/archives/.temp; \
    ls -lhRn /var/archives | egrep "^-rw-r----- 1 1000 1000 .* ROOT-root\.[0-9]*\.master\.tar\.gz$"; \
    test -f /var/archives/ROOT-root.*.master.tar.gz; \
    tar tvzf /var/archives/ROOT-root.*.master.tar.gz | egrep ".* 0/0 .*"; \
    ls -lhRn /tmp; find /tmp -type f -name "unhealthy*" | egrep . && exit 1 || echo OK; \
    date --rfc-3339=seconds | tee /tmp/test-success

FROM test-base AS test-fail
ENV BM_TARBALL_DIRECTORIES="/invalid"
RUN ["/start", "/cron"]
RUN set -eux; echo Test unsuccessful backup; \
    ls -lhRn /tmp; find /tmp -type f -name "unhealthy*" | egrep -v . && exit 1 || echo expected; \
    date --rfc-3339=seconds | tee /tmp/test-fail

# Ensure tests are run before release by copying marker files
FROM test-base AS test
COPY --from=test-success /tmp/test-success /tmp/
COPY --from=test-fail /tmp/test-fail /tmp/
RUN date --rfc-3339=seconds | tee /tmp/tested

# Release
FROM build AS release
COPY --from=test /tmp/tested /tmp/
HEALTHCHECK --interval=1m CMD find /tmp -type f -name "unhealthy*" | egrep . && exit 1 || exit 0
VOLUME /var/archives
