#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

ID_ADMIN_PROJECT=`openstack project list | grep admin | awk '{print $2}'`
ID_SECURITY_GROUP=`openstack security group list | grep $ID_ADMIN_PROJECT | awk '{print $2}'`

#################
echocolor "Tao flavor"
sleep 3
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
openstack flavor create --id 1 --vcpus 1 --ram 512 --disk 1 m1.tiny
openstack flavor create --id 2 --vcpus 2 --ram 1024 --disk 5 m1.small

echocolor "Mo rule can thiet"
sleep 5

openstack security group rule create --protocol icmp $ID_SECURITY_GROUP
openstack security group rule create --protocol tcp --dst-port 22 $ID_SECURITY_GROUP
openstack security group rule create --protocol tcp --dst-port 80:80 $ID_SECURITY_GROUP
openstack security group rule create --protocol tcp --dst-port 443:443 $ID_SECURITY_GROUP
openstack security group rule create --protocol tcp --dst-port 9443:9443 $ID_SECURITY_GROUP

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
	--subnet-range $PROVIDER_SUBNET sub_provider
  
echocolor "Tao VM gan vao provider network"
sleep 5

PROVIDER_NET_ID=`openstack network list | egrep -w provider | awk '{print $2}'`

openstack server create --flavor m1.nano --image cirros \
	--nic net-id=$PROVIDER_NET_ID --security-group $ID_SECURITY_GROUP \
	provider-VM1
  
echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0"
sendtelegram "Da tao xong VM"
notify