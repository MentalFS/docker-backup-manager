FROM debian:stable-slim

# Packages
RUN set -eux; \
	export DEBIAN_FRONTEND=noninteractive; \
	apt update; \
	apt -y install --no-install-recommends \
		backup-manager \
		bzip2 dar gettext-base gpg lzma openssh-client rsync xzip zip \
		cron logrotate rsyslog; \
	apt clean; rm -rf /var/lib/apt/lists/* /var/log/*

# Setup
RUN set -eux; \
	mv /etc/backup-manager.conf /etc/backup-manager.conf.orig; \
	sed -i '/module(load="imklog")/s/^/#/' /etc/rsyslog.conf; \
	sed -i '/RSYSLOG_TraditionalFileFormat/s/^/#/' /etc/rsyslog.conf; \
	touch /var/log/syslog /var/log/user.log

COPY backup-manager.conf /etc/
COPY profile.d-configuration.sh /etc/profile.d/0-configuration.sh
COPY profile.d-services.sh /etc/profile.d/1-services.sh

# Configuration
ENV BM_CRON="0 3 * * *"
ENV BM_ARCHIVE_TTL="14"
ENV BM_REPOSITORY_RECURSIVEPURGE="false"
ENV BM_ARCHIVE_PURGEDUPS="true"
ENV BM_ARCHIVE_PREFIX="DOCKER"
ENV BM_ARCHIVE_STRICTPURGE="true"
ENV BM_ARCHIVE_METHOD="tarball-incremental"
ENV BM_ENCRYPTION_METHOD="false"
ENV BM_ENCRYPTION_RECIPIENT=""
ENV BM_TARBALL_NAMEFORMAT="long"
ENV BM_TARBALL_FILETYPE="tar.gz"
ENV BM_TARBALL_DIRECTORIES="/VOLUME/*"
ENV BM_TARBALL_BLACKLIST=""
ENV BM_TARBALL_SLICESIZE="1000M"
ENV BM_TARBALLINC_MASTERDATETYPE="weekly"
ENV BM_TARBALLINC_MASTERDATEVALUE="1"
ENV BM_UPLOAD_METHOD="none"
ENV BM_UPLOAD_SSH_USER=""
ENV BM_UPLOAD_SSH_KEY=""
ENV BM_UPLOAD_SSH_HOSTS="/root/.ssh/id_rsa"
ENV BM_UPLOAD_SSH_PORT=""
ENV BM_UPLOAD_SSH_DESTINATION=""
ENV BM_UPLOAD_SSH_PURGE="false"
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
ENV BM_UPLOAD_FTP_PURGE="false"
ENV BM_UPLOAD_FTP_TTL=""
ENV BM_UPLOAD_FTP_DESTINATION=""

# Tests
RUN set -eux; \
	test -x /usr/sbin/backup-manager; \
	test -x /etc/profile.d/0-configuration.sh; \
	test -x /etc/profile.d/1-services.sh; \
	export BM_CRON=@reboot; \
	export BM_TARBALL_DIRECTORIES="/root"; \
	mkdir /var/archives; \
	bash -lc "sleep 1"; \
	cat /var/log/syslog; \
	grep @reboot /etc/cron.d/backup-manager; \
	bash /etc/backup-manager.env; \
	bash /etc/backup-manager.conf; \
	test -f /var/archives/DOCKER-root.*.master.tar.gz; \
	rm -rf /var/log/* /var/archives \
		/etc/backup-manager.env /etc/cron.d/backup-manager; \
	touch /var/log/syslog /var/log/user.log

# Runtime
ENV LANG=C.UTF-8
ENV TZ=Europe/Berlin
VOLUME /var/archives
CMD	bash -lc "tail --follow=name -n +1 /var/log/syslog"
