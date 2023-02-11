#!/bin/bash

test -f /etc/backup-manager.env || \
	declare -px | egrep '^declare -x BM_' >/etc/backup-manager.env

test -f /etc/cron.d/backup-manager || \
	echo "$BM_CRON root /usr/sbin/backup-manager" >/etc/cron.d/backup-manager
