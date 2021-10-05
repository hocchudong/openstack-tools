#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg
source /root/admin-openrc

openstack loadbalancer create --name lb01 --vip-subnet-id selfservice

