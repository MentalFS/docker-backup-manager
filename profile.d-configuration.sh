#!/bin/bash

test -f /etc/backup-manager.env \
|| declare -px | egrep '^declare -x BM_' >/etc/backup-manager.env

mkdir -p /var/archives/.temp
test -f /etc/cron.d/backup-manager \
|| echo "$BM_CRON root /usr/sbin/backup-manager >/var/archives/.temp/backup-manager.out" >/etc/cron.d/backup-manager
