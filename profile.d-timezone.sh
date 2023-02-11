#!/bin/bash

test -e "/usr/share/zoneinfo/${TZ}" \
&& ln -fs "/usr/share/zoneinfo/${TZ}" /etc/localtime \
&& dpkg-reconfigure -f noninteractive tzdata |& grep -q "${TZ}" \
|| echo "!!! Timezone could not be set: '${TZ}' !!!"
