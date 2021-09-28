#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

#################
echocolor "Tao flavor"
sleep 3
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano

echocolor "Mo rule ping"
sleep 5
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

echocolor "Tao provider network"
sleep 3
openstack network create --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider

echocolor "Tao subnet cho provider network"
sleep 3
openstack subnet create --network provider \
	--allocation-pool start=$PROVIDER_IP_START,end=$PROVIDER_IP_END \
	--dns-nameserver $PROVIDER_DNS --gateway $PROVIDER_GATEWAY \
	--subnet-range $PROVIDER_SUBNET provider
  
echocolor "Tao VM gan vao provider network"
sleep 5

PROVIDER_NET_ID=`openstack network list | egrep -w provider | awk '{print $2}'`

ID_ADMIN_PROJECT=`openstack project list | grep admin | awk '{print $2}'`
ID_SECURITY_GROUP=`openstack security group list | grep $ID_ADMIN_PROJECT | awk '{print $2}'`

openstack server create --flavor m1.nano --image cirros \
	--nic net-id=$PROVIDER_NET_ID --security-group $ID_SECURITY_GROUP \
	provider-VM1
  
echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0"
sendtelegram "Da tao xong VM"
notify