#!/bin/bash
#Author Son Do Xuan

source function.sh
source config.sh

# Function config hostname
function config_hostname () {
echo "$CTL1_HOSTNAME" > /etc/hostname
echo "$CTL1_IP_NIC1 controller1" >> /etc/hosts
echo "$COM1_IP_NIC1 compute1" >> /etc/hosts
echo "$COM2_IP_NIC1 compute2" >> /etc/hosts
echo "$CINDER1_IP_NIC1 cinder1" >> /etc/hosts
}

# Function IP address
function config_ip () {

cat << EOF > /etc/network/interfaces
# loopback network interface
auto lo
iface lo inet loopback

# VM network
auto ens3
iface ens3 inet static
address $CTL1_IP_NIC1
netmask $NETMASK_NIC1


### API
auto ens4
iface ens4 inet static
address $CTL1_IP_NIC2
netmask $NETMASK_NIC2
gateway $GATAWAY_NIC2
dns-nameservers 8.8.8.8

# Provider Network
# MGNT
auto ens5
iface ens5 inet static
address $CTL1_IP_NIC3
netmask $NETMASK_NIC3
EOF
 
	ip a flush $CTL_EXT_IF
	ip a flush $CTL_MGNT_IF
	ip r del default
	ifdown -a && ifup -a
}

#######################
###Execute functions###
#######################

# Config CONTROLLER node
echocolor "Config CONTROLLER node"
sleep 3

## Config hostname
config_hostname

## IP address
config_ip