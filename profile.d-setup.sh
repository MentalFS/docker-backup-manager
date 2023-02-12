#!/bin/bash

BM_RUN_USER="$(id -un 2>/dev/null||id -u)"
BM_RUN_GROUP="$(id -gn 2>/dev/null||id -g)"
sudo -E /usr/local/bin/backup-manager-setup "${BM_RUN_USER}" "${BM_RUN_GROUP}" || exit 1
test ! -w /var/archives && echo "/var/archives is not writable!" && exit 1

sudo -E /usr/sbin/service rsyslog start >/dev/null || exit 1
sudo -E /usr/sbin/service cron start >/dev/null || exit 1
