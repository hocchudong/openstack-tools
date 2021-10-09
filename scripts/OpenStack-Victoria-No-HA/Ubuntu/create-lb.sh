#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg
source /root/admin-openrc

wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

echocolor "Tao image Ubuntu 18"
openstack image create --disk-format qcow2 --container-format bare \
  --public --file ./bionic-server-cloudimg-amd64.img bionic-server-cloudimg-amd64

sleep 10  
openstack flavor create --ram 1024 --disk 8 --vcpus 1 --public small

ssh-keygen -N "" -f /root/.ssh/id_rsa

openstack keypair create --public-key ~/.ssh/id_rsa.pub controller-key

ID_ADMIN_PROJECT=`openstack project list | grep admin | awk '{print $2}'`
ID_SECURITY_GROUP=`openstack security group list | grep $ID_ADMIN_PROJECT | awk '{print $2}'`
  
sleep 15
openstack server create --flavor small \
  --image bionic-server-cloudimg-amd64 \
  --key-name controller-key \
  --security-group $ID_SECURITY_GROUP \
  --network selfservice \
  ubuntu01

sleep 15
openstack server create --flavor small \
  --image bionic-server-cloudimg-amd64 \
  --key-name controller-key \
  --security-group $ID_SECURITY_GROUP\
  --network selfservice \
  ubuntu02

sleep 60
echocolor "Tao LB"
openstack loadbalancer create --name lb01 --vip-subnet-id sub_selfservice

sleep 600
echocolor "Tao listener cho LB"
openstack loadbalancer listener create --name listener01 --protocol TCP --protocol-port 80 lb01

sleep 60
echocolor "Tao pool cho LB"
openstack loadbalancer pool create --name pool01 --lb-algorithm ROUND_ROBIN --listener listener01 --protocol TCP

IP_VM01=`openstack server list | egrep ubuntu01 | awk '{print $8}' | awk -F= '{print $2}'`
IP_VM02=`openstack server list | egrep ubuntu02 | awk '{print $8}' | awk -F= '{print $2}'`

sleep 60
echocolor "Gan $IP_VM01 vao pool cho LB"
openstack loadbalancer member create --subnet-id sub_selfservice --address $IP_VM01 --protocol-port 80 pool01

sleep 60
echocolor "Gan $IP_VM02 vao pool cho LB"
openstack loadbalancer member create --subnet-id sub_selfservice --address $IP_VM02 --protocol-port 80 pool01

sleep 60
echocolor "Liet ke member cua LB"
openstack loadbalancer member list pool01

echocolor "Cap floating IP cho LB"
openstack floating ip create public

echocolor "I.AM.OK"
