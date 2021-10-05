#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg
source /root/admin-openrc


wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

openstack image create --disk-format qcow2 --container-format bare \
  --public --file ./bionic-server-cloudimg-amd64.img bionic-server-cloudimg-amd64

sleep 10  
openstack flavor create --ram 1024 --disk 8 --vcpus 1 --public small

ssh-keygen -N "" -f /root/.ssh/id_rsa

openstack keypair create --public-key ~/.ssh/id_rsa.pub controller-key

openstack security group create allow-all-traffic --description 'Allow All Ingress Traffic'
openstack security group rule create --protocol icmp allow-all-traffic
openstack security group rule create --protocol tcp  allow-all-traffic
openstack security group rule create --protocol udp  allow-all-traffic


sleep 15
openstack server create --flavor small \
  --image bionic-server-cloudimg-amd64 \
  --key-name controller-key \
  --security-group allow-all-traffic \
  --network sub-selfservice \
  ubuntu01

sleep 15
openstack server create --flavor small \
  --image bionic-server-cloudimg-amd64 \
  --key-name controller-key \
  --security-group allow-all-traffic \
  --network sub-selfservice \
  ubuntu02

sleep 30
openstack loadbalancer create --name lb01 --vip-subnet-id sub-selfservice

sleep 120
openstack loadbalancer listener create --name listener01 --protocol TCP --protocol-port 80 lb01

sleep 30
openstack loadbalancer pool create --name pool01 --lb-algorithm ROUND_ROBIN --listener listener01 --protocol TCP


IP_VM01=`openstack server list | egrep ubuntu01 | awk '{print $8}' | awk -F= '{print $2}'`
IP_VM02=`openstack server list | egrep ubuntu02 | awk '{print $8}' | awk -F= '{print $2}'`


sleep 30
openstack loadbalancer member create --subnet-id sub-selfservice --address $IP_VM01 --protocol-port 80 pool01

sleep 30
openstack loadbalancer member create --subnet-id sub-selfservice --address $IP_VM02 --protocol-port 80 pool01

sleep 30
openstack loadbalancer member list pool01


openstack floating ip create public