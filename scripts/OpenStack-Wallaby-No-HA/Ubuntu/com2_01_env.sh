#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

function config_hostname () {
  hostnamectl set-hostname $COM2_HOSTNAME
  
  echo "127.0.0.1 locahost $COM2_HOSTNAME" > /etc/hosts
  echo "$CTL1_IP_NIC2 $CTL1_HOSTNAME" >> /etc/hosts
  echo "$COM1_IP_NIC2 $COM1_HOSTNAME" >> /etc/hosts
  echo "$COM2_IP_NIC2 $COM2_HOSTNAME" >> /etc/hosts
  echo "$CINDER1_IP_NIC2 $CINDER1_HOSTNAME" >> /etc/hosts
}

# Function update and upgrade for COMPUTE
function update_upgrade () {
  echocolor "Update and Upgrade COMPUTE"
  sleep 3
  apt-get update -y && apt-get upgrade -y
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
  sudo apt-get install software-properties-common -y  2>&1
  sudo add-apt-repository cloud-archive:wallaby -y 2>&1
  
  sudo echo "deb http://172.16.70.131:8081/repository/u20wallaby/ focal-updates/wallaby main" >  /etc/apt/sources.list.d/cloudarchive-wallaby.list

  sudo apt-get update -y 2>&1 
  sudo apt-get upgrade -y 2>&1 
  sudo apt-get install python3-openstackclient -y 2>&1 
  
  systemctl disable ufw
  systemctl stop ufw
}

#######################
###Execute functions###
#######################
sendtelegram "Thuc thi script $0 tren `hostname`"

sendtelegram "Thuc thi config_hostname `hostname`"
config_hostname

# Update and upgrade for COMPUTE
sendtelegram "Thuc thi update_upgrade tren `hostname`"
update_upgrade

# Install and config NTP
sendtelegram "Thuc thi install_ntp tren `hostname`"
install_ntp

# OpenStack packages (python-openstackclient)
sendtelegram "Thuc thi install_ops_packages tren `hostname`"
install_ops_packages

TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0 tren `hostname`, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0 tren `hostname`, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify
