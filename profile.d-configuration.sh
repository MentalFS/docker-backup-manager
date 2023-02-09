#!/bin/bash

test -f /etc/backup-manager.env || \
	declare -px | egrep '^declare -x BM_' >/etc/backup-manager.env
