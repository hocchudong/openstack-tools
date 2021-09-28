#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

openstack volume create --size 10 disk01

sleep 10 

openstack server add volume provider-VM1 disk01