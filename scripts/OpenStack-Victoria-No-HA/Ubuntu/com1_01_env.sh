#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

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
  sudo apt-get install software-properties-common -y 2>&1 | tee -a filelog-install.txt
  sudo add-apt-repository cloud-archive:wallaby -y 2>&1 | tee -a filelog-install.txt
  
  sudo echo "deb http://172.16.70.131:8081/repository/u20wallaby/ focal-updates/wallaby main" >  /etc/apt/sources.list.d/cloudarchive-wallaby.list

  sudo apt-get update -y 2>&1 | tee -a filelog-install.txt
  sudo apt-get upgrade -y 2>&1 | tee -a filelog-install.txt
  sudo apt-get install python3-openstackclient -y 2>&1 | tee -a filelog-install.txt
}

#######################
###Execute functions###
#######################
sendtelegram "Thuc thi script $0 tren `hostname`"

# Update and upgrade for COMPUTE
sendtelegram "Cai update_upgrade tren `hostname`"
update_upgrade

# Install and config NTP
sendtelegram "Cai install_ntp tren `hostname`"
install_ntp

# OpenStack packages (python-openstackclient)
sendtelegram "Cai install_ops_packages tren `hostname`"
install_ops_packages

TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify
