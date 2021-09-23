#!/bin/bash
# Author: HOC CHU DONG
source function.sh
source config.cfg

# Function config hostname
function config_hostname () {
echo "$COM1_HOSTNAME" > /etc/hostname
echo "127.0.0.1 locahost $COM1_HOSTNAME" > /etc/hosts
echo "$CTL1_IP_NIC2 $CTL1_HOSTNAME" >> /etc/hosts
echo "$COM1_IP_NIC2 $COM1_HOSTNAME" >> /etc/hosts
echo "$COM2_IP_NIC2 $COM2_HOSTNAME" >> /etc/hosts
echo "$CINDER1_IP_NIC2 $CINDER1_HOSTNAME" >> /etc/hosts
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
address $COM1_IP_NIC1
netmask $NETMASK_NIC1


### API
auto ens4
iface ens4 inet static
address $COM1_IP_NIC2
netmask $NETMASK_NIC2
gateway $GATAWAY_NIC2
dns-nameservers 8.8.8.8

# Provider Network
# MGNT
auto ens5
iface ens5 inet static
address $COM1_IP_NIC3
netmask $NETMASK_NIC3
EOF
}

#######################
###Execute functions###
#######################

# Config CONTROLLER node
echocolor "Config $COM1_HOSTNAME node"
sleep 3

## Config hostname
config_hostname

## IP address
config_ip

echocolor "Reboot $COM1_HOSTNAME node"
init 6

