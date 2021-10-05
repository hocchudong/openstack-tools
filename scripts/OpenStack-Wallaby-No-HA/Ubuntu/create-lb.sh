#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg
source /root/admin-openrc

openstack loadbalancer create --name lb01 --vip-subnet-id selfservice


openstack loadbalancer listener create --name listener01 --protocol TCP --protocol-port 80 lb01


openstack loadbalancer pool create --name pool01 --lb-algorithm ROUND_ROBIN --listener listener01 --protocol TCP

openstack loadbalancer member create --subnet-id private-subnet --address 192.168.100.43 --protocol-port 80 pool01

openstack loadbalancer member create --subnet-id private-subnet --address 192.168.100.132 --protocol-port 80 pool01

openstack loadbalancer member list pool01


openstack floating ip create public