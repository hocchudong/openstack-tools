#!/bin/bash
#Author HOC CHU DONG

source function.sh
source config.sh

# Function update and upgrade for CONTROLLER
function update_upgrade () {
	echocolor "Update and Update controller"
	sleep 3
	apt-get update -y&& apt-get upgrade -y
}

# Function install crudini
function install_crudini () {
	echocolor "Install crudini"
	sleep 3
	apt-get install -y crudini
}

# Function install and config NTP
function install_ntp () {
	echocolor "Install NTP"
	sleep 3

	apt-get install chrony -y
	ntpfile=/etc/chrony/chrony.conf

	sed -i 's/pool 2.debian.pool.ntp.org offline iburst/ \
pool 2.debian.pool.ntp.org offline iburst \
server 0.asia.pool.ntp.org iburst \
server 1.asia.pool.ntp.org iburst/g' $ntpfile

	echo "allow 172.16.68.0/24" >> $ntpfile

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

# Function install mysql
function install_sql () {
	echocolor "Install SQL database - Mariadb"
	sleep 3

	apt-get install mariadb-server python-pymysql  -y

	sqlfile=/etc/mysql/mariadb.conf.d/99-openstack.cnf
	touch $sqlfile
	cat << EOF >$sqlfile
[mysqld]
bind-address = $CTL_MGNT_IP
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

service mysql restart
}

# Function install message queue
function install_mq () {
	echocolor "Install Message queue (rabbitmq)"
	sleep 3

	apt-get install rabbitmq-server -y
	rabbitmqctl add_user openstack $RABBIT_PASS
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
}

# Function install Memcached
function install_memcached () {
	echocolor "Install Memcached"
	sleep 3

	apt-get install memcached python-memcache -y
	memcachefile=/etc/memcached.conf
	sed -i 's|-l 127.0.0.1|'"-l $CTL1_IP_NIC2"'|g' $memcachefile

	service memcached restart
} 

#######################
###Execute functions###
#######################

# Update and upgrade for controller
update_upgrade

# Install crudini
install_crudini

# Install and config NTP
install_ntp

# OpenStack packages (python-openstackclient)
install_ops_packages

# Install SQL database (Mariadb)
install_sql

# Install Message queue (rabbitmq)
install_mq

# Install Memcached
install_memcached