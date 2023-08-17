FROM debian:stable-20230814-slim AS build

# Setup
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt update; \
    apt -y install --no-install-recommends \
        cron tzdata rsyslog logrotate \
        bzip2 gettext-base gpg lzma openssh-client rsync xz-utils \
        backup-manager; \
    apt clean; rm -rf /var/lib/apt/lists/* /var/log/*

RUN set -eux; \
    sed -i '/module(load="imklog")/s/^/#/' /etc/rsyslog.conf; \
    sed -i '/RSYSLOG_TraditionalFileFormat/s/^/#/' /etc/rsyslog.conf; \
    mv /etc/backup-manager.conf /etc/backup-manager.conf.orig; \
    chown backup:backup /var/backups; \
    chmod g+rw /var/backups

COPY bin/start /
COPY bin/cron /
COPY bin/backup-manager /
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
FROM build AS test
RUN set -eux; \
	test -e /root; test -r /root; \
    chmod a+rX /root -R; \
    ls -lha /root; \
    stat -c "%n %U %G %a" /etc/backup-manager.conf; \
    stat -c "%a" /etc/backup-manager.conf | egrep '^644$'; \
    mkdir -p /var/archives/.temp
ENV BM_CRON=@reboot \
    BM_TARBALL_DIRECTORIES="/root" \
    BM_ARCHIVE_PREFIX="ROOT" \
    BM_REPOSITORY_USER="1000" \
    BM_REPOSITORY_GROUP="1000"
RUN sed 's:^exec \(.*\):timeout 5 \1 || echo OK:' /start -i
RUN ["/start", "/cron"]
RUN set -eux; \
    cat /etc/cron.d/backup-manager; \
    cat /var/log/syslog; \
    find /var/archives/.temp/ -type f -exec cat {} + ; \
    ls -lhRn /var/archives; \
    ls -lhRn /var/archives | egrep "^-rw-r----- 1 1000 1000 .* ROOT-root\.[0-9]*\.master\.tar\.gz$"; \
    test -f /var/archives/ROOT-root.*.master.tar.gz; \
    tar tvzf /var/archives/ROOT-root.*.master.tar.gz | egrep ".* 0/0 .*"


# Release
FROM build AS release
VOLUME /var/archives
