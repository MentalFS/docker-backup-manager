FROM scratch AS download
ARG BM_VERSION=0.7.14
ADD "https://github.com/sukria/Backup-Manager/archive/refs/tags/${BM_VERSION}.tar.gz" "/root/Backup-Manager-${BM_VERSION}.tar.gz"


FROM alpine:3.18.2 AS build
RUN apk add --no-cache s6-overlay s6-overlay-syslogd ca-certificates tzdata
RUN apk add --no-cache perl # largest dep
RUN apk add --no-cache bash bzip2 coreutils gpg gzip make openssh-client rsync tar xz
COPY --from=download /root/Backup-Manager-*.tar.gz /root/
RUN set -eux; \
    cd /root; \
    tar xzf Backup-Manager-*.tar.gz; \
    cd Backup-Manager-*/; \
    make install_binary; \
    cd -; \
    rm -rf Backup-Manager-*/
RUN set -eux; \
    echo "#!/command/with-contenv sh" >/command/backup-manager; \
    echo "/usr/local/sbin/backup-manager" >>/command/backup-manager; \
    chmod a+x /command/backup-manager; \
    ln -s /command/backup-manager /command/run; \
    ln -s /etc/backup-manager/backup-manager.conf /etc/backup-manager.conf
COPY ./etc/ /etc/
ENTRYPOINT ["/init"]

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


# Test
FROM build AS test
RUN set -eux; \
	test -e /root; test -r /root; \
    chmod a+rX /root -R; \
    ls -lha /root; \
    stat -c "%n %U %G %a" /etc/backup-manager/backup-manager.conf; \
    stat -c "%a" /etc/backup-manager/backup-manager.conf | egrep '^644$'; \
    mkdir -p /var/archives/.temp
ENV BM_CRON=@reboot \
    BM_TARBALL_DIRECTORIES="/root" \
    BM_ARCHIVE_PREFIX="ROOT" \
    BM_REPOSITORY_USER="1000" \
    BM_REPOSITORY_GROUP="1000"
RUN ["/init", "sleep", "5"]
RUN set -eux; \
    cat /var/spool/cron/crontabs/root; \
    cat /var/log/syslogd/messages/current; \
    find /var/archives/.temp/ -type f -exec cat {} + ; \
    ls -lhRn /var/archives; \
    ls -lhRn /var/archives | egrep "^-rw-r----- 1 1000 1000 .* ROOT-root\.[0-9]*\.master\.tar\.gz$"; \
    test -f /var/archives/ROOT-root.*.master.tar.gz; \
    tar tvzf /var/archives/ROOT-root.*.master.tar.gz | egrep ".* 0/0 .*"


# Release
FROM build AS release
VOLUME /var/archives
