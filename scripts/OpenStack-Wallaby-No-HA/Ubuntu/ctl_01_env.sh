#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

function config_hostname () {

  hostnamectl set-hostname $CTL1_HOSTNAME
  
  
  echo "$CTL1_IP_NIC2 $CTL1_HOSTNAME" > /etc/hosts
  echo "$COM1_IP_NIC2 $COM1_HOSTNAME" >> /etc/hosts
  echo "$COM2_IP_NIC2 $COM2_HOSTNAME" >> /etc/hosts
  
  echo "127.0.0.1 $CTL1_HOSTNAME" >> /etc/hosts
  echo "127.0.0.2 localhost" >> /etc/hosts

}


# Function update and upgrade for CONTROLLER
function update_upgrade () {
	echocolor "Update and Update controller"
	sleep 3
	apt-get update -y&& apt-get upgrade -y
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

	echo "allow 172.16.70.0/24" >> $ntpfile

	service chrony restart 
}

# Function install OpenStack packages (python-openstackclient)
function install_ops_packages () {
	echocolor "Install OpenStack client"
	sleep 3
	sudo apt-get install software-properties-common -y 
  sudo add-apt-repository cloud-archive:wallaby -y 
  sudo echo "deb http://172.16.70.131:8081/repository/u20wallaby/ focal-updates/wallaby main" > /etc/apt/sources.list.d/cloudarchive-wallaby.list
  
  sudo apt update -y 
  sudo apt upgrade -y 
  sudo apt install crudini -y
  sudo apt install python3-openstackclient -y 
  
  systemctl disable ufw
  systemctl stop ufw
}

function install_database() {
	echocolor "Install and Config MariaDB"
	sleep 3

	echo mariadb-server-10.0 mysql-server/root_password $PASS_DATABASE_ROOT | debconf-set-selections
	echo mariadb-server-10.0 mysql-server/root_password_again $PASS_DATABASE_ROOT | debconf-set-selections

	sudo apt install mariadb-server python3-pymysql -y 2>&1 | tee -a filelog-install.txt


	sed -r -i 's/127\.0\.0\.1/0\.0\.0\.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
	sed -i 's/character-set-server  = utf8mb4/character-set-server  = utf8/' /etc/mysql/mariadb.conf.d/50-server.cnf
	sed -i 's/collation-server/#collation-server/' /etc/mysql/mariadb.conf.d/50-server.cnf

	systemctl restart mysql

cat << EOF | mysql -uroot -p$PASS_DATABASE_ROOT 
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$PASS_DATABASE_ROOT' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$PASS_DATABASE_ROOT' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

	sqlfile=/etc/mysql/mariadb.conf.d/99-openstack.cnf
	touch $sqlfile	
	ops_add $sqlfile client default-character-set utf8
	ops_add $sqlfile mysqld bind-address 0.0.0.0
	ops_add $sqlfile mysqld default-storage-engine innodb
	ops_add $sqlfile mysqld innodb_file_per_table
	ops_add $sqlfile mysqld max_connections 4096
	ops_add $sqlfile mysqld collation-server utf8_general_ci
	ops_add $sqlfile mysqld character-set-server utf8

	echocolor "Restarting MYSQL"
	sleep 5
	systemctl restart mysql

}


# Function install message queue
function install_mq () {
	echocolor "Install Message queue (rabbitmq)"
	sleep 3

	sudo apt -y install rabbitmq-server memcached python3-pymysql
	rabbitmqctl add_user openstack $RABBIT_PASS
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
}

# Function install Memcached
function install_memcached () {
	echocolor "Install Memcached"
	sleep 3

	apt-get install memcached python3-memcache -y
	memcachefile=/etc/memcached.conf
	sed -i 's|-l 127.0.0.1|'"-l $CTL1_IP_NIC2"'|g' $memcachefile

	systemctl restart mariadb rabbitmq-server memcached 2>&1 | tee -a filelog-install.txt
} 

# Function install Memcached
function install_etcd () {
	echocolor "Install etcd"
	sleep 3

	apt install etcd -y
cat << EOF >  /etc/default/etcd
ETCD_NAME="`hostname`"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER="`hostname`=http://$CTL1_IP_NIC2:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$CTL1_IP_NIC2:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://$CTL1_IP_NIC2:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://$CTL1_IP_NIC2:2379"
EOF
	 systemctl enable etcd 2>&1 | tee -a filelog-install.txt
	 systemctl restart etcd 2>&1 | tee -a filelog-install.txt
} 


#######################
###Execute functions###
#######################

sendtelegram "Thuc thi script $0 tren `hostname`"

sendtelegram "Thuc thi config_hostname tren `hostname`"
config_hostname

# Update and upgrade for controller
sendtelegram "Thuc thi update_upgrade tren `hostname`"
update_upgrade

# Install and config NTP
sendtelegram "Thuc thi install_ntptren `hostname`"
install_ntp

# OpenStack packages (python-openstackclient)
sendtelegram "Thuc thi install_ops_packages tren `hostname`"
install_ops_packages

# Install SQL database (Mariadb)
sendtelegram "Thuc thi install_database tren `hostname`"
install_database

# Install Message queue (rabbitmq)
sendtelegram "Thuc thi install_mq tren `hostname`"
install_mq

# Install Memcached
sendtelegram "Thuc thi install_memcachedtren `hostname`"
install_memcached

sendtelegram "Thuc thi install_etc tren `hostname`"
install_etcd

TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify

