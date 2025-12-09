# check=skip=SecretsUsedInArgOrEnv
FROM debian:stable-20251208-slim AS build

# Setup
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    rm -fv /etc/cron*/*; \
    apt update; \
    apt -y install --no-install-recommends cron anacron \
        ca-certificates bzip2 gettext-base gnupg lzma openssh-client rsync xz-utils \
        backup-manager; \
    rm -fv /etc/cron*/anacron; \
    apt clean; rm -rf /var/lib/apt/lists/* /var/log/*

RUN set -eux; \
    test -f /usr/share/perl5/BackupManager/Logger.pm \
    && sed -i "/^\\s*setlogsock('unix');\\s*$/s/^/#/" /usr/share/perl5/BackupManager/Logger.pm; \
    mv /etc/backup-manager.conf /etc/backup-manager.conf.orig; \
    mv /etc/anacrontab /etc/anacrontab.orig; \
    chown backup:backup /var/backups; chmod g+rw /var/backups; \
    mkdir -p /etc/gnupg; echo always-trust > /etc/gnupg/gpg.conf; chmod -R go-rwx /etc/gnupg; \
    echo "StrictHostKeyChecking=accept-new" >> /etc/ssh/ssh_config.d/accept-new.conf

COPY etc /etc
COPY bin/* /
ENTRYPOINT ["/start"]
CMD ["/cron"]

# Configuration
ENV CRON_SCHEDULE="@hourly" \
    BM_REPOSITORY_USER="root" \
    BM_REPOSITORY_GROUP="root" \
    BM_REPOSITORY_RECURSIVEPURGE="false" \
    BM_ARCHIVE_PURGEDUPS="true" \
    BM_ARCHIVE_PREFIX="DOCKER" \
    BM_ARCHIVE_STRICTPURGE="true" \
    BM_ARCHIVE_METHOD="tarball-incremental" \
    BM_ARCHIVE_TTL="14" \
    BM_ENCRYPTION_METHOD="none" \
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
    BM_UPLOAD_SSH_PORT="22" \
    BM_UPLOAD_SSH_DESTINATION="" \
    BM_UPLOAD_SSH_PURGE="true" \
    BM_UPLOAD_SSH_TTL="" \
    BM_UPLOAD_SSHGPG_RECIPIENT="" \
    BM_UPLOAD_RSYNC_DIRECTORIES="/var/archives/" \
    BM_UPLOAD_RSYNC_DESTINATION="" \
    BM_UPLOAD_RSYNC_HOSTS="" \
    BM_UPLOAD_RSYNC_BLACKLIST="" \
    BM_UPLOAD_RSYNC_BANDWIDTH_LIMIT="" \
    BM_UPLOAD_RSYNC_EXTRA_OPTIONS="--delete" \
    GNUPGIMPORT="/etc/gnupg/import.gpg" \
    LANG=C.UTF-8 \
    TZ=Europe/Berlin


# Tests
FROM build AS test-base

RUN set -eux; \
	test -e /root; test -r /root; \
    chmod a+rX /root -R; \
    ls -lha /root /etc/cron* /etc/backup*; \
    stat -c "%n %U %G %a" /etc/backup-manager.conf; \
    stat -c "%a" /etc/backup-manager.conf | egrep '^644$'; \
    mkdir -p /var/archives/.temp
ENV CRON_SCHEDULE=@reboot \
    BM_ARCHIVE_PREFIX="ROOT" \
    BM_REPOSITORY_USER="1000" \
    BM_REPOSITORY_GROUP="1000"

FROM test-base AS test-success
ENV BM_TARBALL_DIRECTORIES="/root"
RUN ["/start", "/anacron"]
RUN set -eux; echo Test successful backup; \
    find /var/archives/.temp/ -type f -exec cat {} + ; \
    ls -lhRn /var/archives /var/archives/.temp /var/archives/.anacron; \
    ls -lhRn /var/archives | egrep "^-rw-r----- 1 1000 1000 .* ROOT-root\.[0-9]*\.master\.tar\.gz$"; \
    test -f /var/archives/ROOT-root.*.master.tar.gz; \
    tar tvzf /var/archives/ROOT-root.*.master.tar.gz | egrep ".* 0/0 .*"; \
    ls -lhRn /tmp; find /tmp -type f -name "unhealthy*" -exec false {} + || exit 1 && echo OK; \
    date --rfc-3339=seconds | tee /tmp/test-success

FROM test-base AS test-fail
ENV BM_TARBALL_DIRECTORIES="/invalid"
RUN ["/start", "/backup-manager"]
RUN set -eux; echo Test unsuccessful backup; \
    ls -lhRn /tmp; find /tmp -type f -name "unhealthy*" -exec false {} + && exit 1 || echo No unhealthy marker; \
    date --rfc-3339=seconds | tee /tmp/test-fail

# Ensure tests are run before release by copying marker files
FROM test-base AS test
COPY --from=test-success /tmp/test-success /tmp/
COPY --from=test-fail /tmp/test-fail /tmp/
RUN date --rfc-3339=seconds | tee /tmp/tested

# Release
FROM build AS release
COPY --from=test /tmp/tested /tmp/
RUN rm /tmp/tested
HEALTHCHECK --interval=1m CMD find /tmp -type f -name "unhealthy*" -exec false {} + || exit 1
VOLUME /var/archives
