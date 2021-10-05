#!/bin/bash 

###############################################################################
## Init enviroiment source
source config.cfg
source function.sh

###############################################################################
echocolor "Tao private network (selfservice network)"
sleep 3
openstack network create selfservice

echocolor "Tao subnnet cho private network"
sleep 3
 openstack subnet create --network selfservice \
 	--dns-nameserver $PRIVATE_DNS --gateway $PRIVATE_GATEWAY \
 	--subnet-range $PRIVATE_SUBNET sub-selfservice

echocolor "Tao va gan inteface cho ROUTER"
sleep 3
openstack router create R1
neutron router-interface-add R1 selfservice
neutron router-gateway-set R1 provider

echocolor "Tao may ao gan vao private network (selfservice network)"
sleep 5
ID_ADMIN_PROJECT=`openstack project list | grep admin | awk '{print $2}'`
ID_SECURITY_GROUP=`openstack security group list | grep $ID_ADMIN_PROJECT | awk '{print $2}'`

PRIVATE_NET_ID=`openstack network list | egrep -w selfservice | awk '{print $2}'`

openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$PRIVATE_NET_ID --security-group $ID_SECURITY_GROUP \
  selfservice-VM1


echocolor "Floatig IP"
sleep 5
FLOATING_IP=`openstack floating ip create provider | egrep -w floating_ip_address | awk '{print $4}'`
openstack server add floating ip selfservice-VM1 $FLOATING_IP