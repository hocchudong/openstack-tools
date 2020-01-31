#!/bin/bash
#Author HOC CHU DONG 

source function.sh
source config.cfg

# Function update and upgrade for COMPUTE
function update_upgrade () {
	echocolor "Update and Upgrade COMPUTE"
	sleep 3
	apt-get update -y && apt-get upgrade -y
}

# Function install crudini
function install_crudini () {
	echocolor "Install crudini"
	sleep 3
	apt-get install -y crudini vim byobu
}

# Function install and config NTP
function install_ntp () {
	echocolor "Install NTP"
	sleep 3

	apt-get install chrony -y
	ntpfile=/etc/chrony/chrony.conf

	sed -i 's|'"pool 2.debian.pool.ntp.org offline iburst"'| \
	'"server $HOST_CTL iburst"'|g' $ntpfile

	service chrony restart
}

# Function install OpenStack packages (python-openstackclient)
function install_ops_packages () {
	echocolor "Install OpenStack client"
	sleep 3
	apt-get install software-properties-common -y
	add-apt-repository cloud-archive:queens -y
	apt-get update -y && apt-get dist-upgrade -y

	apt-get install python-openstackclient -y
}

#######################
###Execute functions###
#######################

# Update and upgrade for COMPUTE
update_upgrade

# Install crudini
install_crudini

# Install and config NTP
install_ntp

# OpenStack packages (python-openstackclient)
install_ops_packages