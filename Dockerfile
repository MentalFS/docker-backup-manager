FROM debian:stable-slim as build

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt update; \
    apt -y install --no-install-recommends \
        backup-manager \
        bzip2 gettext-base gpg lzma openssh-client rsync xz-utils \
        cron logrotate rsyslog sudo tzdata; \
    apt clean; rm -rf /var/lib/apt/lists/* /var/log/*

RUN set -eu; \
    seq 900 1100 | while read NUMBER; do \
        groupadd -r "gid${NUMBER}" -g "${NUMBER}"; \
        useradd -u "${NUMBER}" -g "gid${NUMBER}" -G backup -d /var/backups "uid${NUMBER}"; \
    done

RUN set -eux; \
    sed -i '/module(load="imklog")/s/^/#/' /etc/rsyslog.conf; \
    sed -i '/RSYSLOG_TraditionalFileFormat/s/^/#/' /etc/rsyslog.conf; \
    mv /etc/backup-manager.conf /etc/backup-manager.conf.orig; \
    chown backup:backup /var/backups; \
    chmod g+rw /var/backups

COPY backup-manager.conf /etc/
COPY sudoers.d-setup.conf /etc/sudoers.d/backup-manager-setup
COPY profile.d-setup.sh /etc/profile.d/00-backup-manager-setup.sh
COPY bin-setup.sh /usr/local/bin/backup-manager-setup
COPY bin-log.sh /usr/local/bin/backup-manager-log

RUN set -eux; \
    chmod a+r /etc/backup-manager.conf; \
    chmod a-w,o-r /etc/sudoers.d/backup-manager-setup; \
    chmod a+rx /etc/profile.d/00-backup-manager-setup.sh; \
    chmod a+rx /usr/local/bin/backup-manager-setup; \
    chmod a+rx /usr/local/bin/backup-manager-log; \
    touch /var/log/syslog /var/log/user.log /var/log/messages


# Configuration
ENV BM_CRON="0 3 * * *"
ENV BM_REPOSITORY_USER=""
ENV BM_REPOSITORY_GROUP=""
ENV BM_REPOSITORY_RECURSIVEPURGE="false"
ENV BM_ARCHIVE_PURGEDUPS="true"
ENV BM_ARCHIVE_PREFIX="DOCKER"
ENV BM_ARCHIVE_STRICTPURGE="true"
ENV BM_ARCHIVE_METHOD="tarball-incremental"
ENV BM_ARCHIVE_TTL="14"
ENV BM_ENCRYPTION_METHOD="false"
ENV BM_ENCRYPTION_RECIPIENT=""
ENV BM_TARBALL_NAMEFORMAT="long"
ENV BM_TARBALL_FILETYPE="tar.gz"
ENV BM_TARBALL_DIRECTORIES="/VOLUME/*"
ENV BM_TARBALL_BLACKLIST=""
ENV BM_TARBALLINC_MASTERDATETYPE="weekly"
ENV BM_TARBALLINC_MASTERDATEVALUE="1"
ENV BM_UPLOAD_METHOD="none"
ENV BM_UPLOAD_SSH_USER=""
ENV BM_UPLOAD_SSH_KEY="/etc/ssh/id_rsa"
ENV BM_UPLOAD_SSH_HOSTS=""
ENV BM_UPLOAD_SSH_PORT=""
ENV BM_UPLOAD_SSH_DESTINATION=""
ENV BM_UPLOAD_SSH_PURGE="true"
ENV BM_UPLOAD_SSH_TTL=""
ENV BM_UPLOAD_SSHGPG_RECIPIENT=""
ENV BM_UPLOAD_RSYNC_DIRECTORIES="/var/archives"
ENV BM_UPLOAD_RSYNC_DESTINATION=""
ENV BM_UPLOAD_RSYNC_HOSTS=""
ENV BM_UPLOAD_RSYNC_BLACKLIST=""
ENV BM_UPLOAD_RSYNC_BANDWIDTH_LIMIT=""
ENV BM_UPLOAD_FTP_USER=""
ENV BM_UPLOAD_FTP_PASSWORD=""
ENV BM_UPLOAD_FTP_HOSTS=""
ENV BM_UPLOAD_FTP_PURGE="true"
ENV BM_UPLOAD_FTP_TTL=""
ENV BM_UPLOAD_FTP_DESTINATION=""
ENV GNUPGHOME="/etc/gnupg"
ENV LANG=C.UTF-8
ENV LOGFILE="messages"
ENV TZ=Europe/Berlin


# Tests
FROM build
RUN set -eux; \
    egrep '^uid' /etc/passwd | wc -l | egrep '^201$'; \
    stat -c "%n %U %G %a" /etc/backup-manager.conf; \
    stat -c "%a" /etc/backup-manager.conf | egrep '^644$'; \
    stat -c "%n %U %G %a" /etc/sudoers.d/backup-manager-setup; \
    stat -c "%a" /etc/sudoers.d/backup-manager-setup | egrep '^440$'; \
    stat -c "%n %U %G %a" /etc/profile.d/00-backup-manager-setup.sh; \
    stat -c "%a" /etc/profile.d/00-backup-manager-setup.sh | egrep '^755$'; \
    stat -c "%n %U %G %a" /usr/local/bin/backup-manager-setup; \
    stat -c "%a" /usr/local/bin/backup-manager-setup | egrep '^755$'; \
    stat -c "%n %U %G %a" /usr/local/bin/backup-manager-log; \
    stat -c "%a" /usr/local/bin/backup-manager-log | egrep '^755$'; \
    export BM_CRON=@reboot; \
    export BM_TARBALL_DIRECTORIES="/root"; \
    export BM_ARCHIVE_PREFIX="ROOT"; \
    mkdir /var/archives; \
    sudo -E bash -lc "sleep 1"; \
    cat /var/log/${LOGFILE}; \
    cat /etc/cron.d/backup-manager; \
    grep @reboot /etc/cron.d/backup-manager; \
    bash /etc/backup-manager.env; \
    bash /etc/backup-manager.conf; \
    ls -lh /var/archives /var/archives/.temp*; \
    test -f /var/archives/ROOT-root.*.master.tar.gz; \
    tar tvzf /var/archives/ROOT-root.*.master.tar.gz | egrep ".* 0/0 .*"

FROM build as test
RUN set -eux; \
    mkdir /var/archives; \
    chown backup:backup /var/archives
USER backup:backup
RUN set -eux; \
    export BM_TARBALL_DIRECTORIES="/var/backups"; \
    export BM_ARCHIVE_PREFIX="BACKUP"; \
    /etc/profile.d/00-backup-manager-setup.sh; \
    cat /etc/cron.d/backup-manager; \
    grep " backup " /etc/cron.d/backup-manager; \
    /usr/sbin/backup-manager; \
    ls -lh /var/archives /var/archives/.temp*; \
    test -f /var/archives/BACKUP-var-backups.*.master.tar.gz; \
    stat -c "%U:%G" /var/archives/BACKUP-var-backups.*.master.tar.gz | egrep "backup:backup"; \
    tar tvzf /var/archives/BACKUP-var-backups.*.master.tar.gz | egrep ".* 34/34 .*"


# Release
FROM build as release
USER backup:backup
VOLUME /var/archives
CMD /usr/local/bin/backup-manager-log "${LOGFILE}"
