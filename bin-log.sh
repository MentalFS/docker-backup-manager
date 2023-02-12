#!/bin/bash -l

LOGFILE="${1//[^a-z0-9\.]/}"

tail --follow=name -n +1 "/var/log/${LOGFILE}"

