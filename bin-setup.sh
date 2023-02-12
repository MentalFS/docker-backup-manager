#!/bin/bash

BM_RUN_USER="${1//[^a-z0-9\.]/}"
BM_RUN_GROUP="${2//[^a-z0-9\.]/}"

test -e "/usr/share/zoneinfo/${TZ}" \
&& ln -fs "/usr/share/zoneinfo/${TZ}" /etc/localtime \
&& dpkg-reconfigure -f noninteractive tzdata |& grep -q "${TZ}" \
|| echo "!!! Timezone could not be set: '${TZ}' !!!"


test -f /etc/backup-manager.env \
|| declare -px | egrep '^declare -x BM_' >/etc/backup-manager.env
chmod a+r /etc/backup-manager.env

test -f /etc/cron.d/backup-manager \
|| echo "$BM_CRON ${BM_RUN_USER} /usr/sbin/backup-manager >/dev/null" >/etc/cron.d/backup-manager
