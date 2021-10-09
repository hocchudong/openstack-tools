#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

# Function create database for Glance
function glance_create_db () {
  echocolor "Create database for Glance"
  sleep 3

cat << EOF | mysql -uroot -p$PASS_DATABASE_ROOT
CREATE DATABASE glance default character set utf8;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$PASS_DATABASE_GLANCE' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$PASS_DATABASE_GLANCE' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
}

# Function create the Glance service credentials
function glance_create_service () {
  echocolor "Set variable environment for admin user"
  sleep 3
  source /root/admin-openrc

  echocolor "Create the service credentials"
  sleep 3

  openstack user create --domain default --password $GLANCE_PASS glance
  openstack role add --project service --user glance admin
  openstack service create --name glance --description "OpenStack Image" image
  
  openstack endpoint create --region RegionOne image public http://$CTL1_IP_NIC2:9292
  openstack endpoint create --region RegionOne image internal http://$CTL1_IP_NIC2:9292
  openstack endpoint create --region RegionOne image admin http://$CTL1_IP_NIC2:9292
}

# Function install components of Glance
function glance_install () {
  echocolor "Install and configure components of Glance"
  sleep 3

  apt install glance -y
}

# Function config /etc/glance/glance-api.conf file
function glance_config_api () {
  glanceapifile=/etc/glance/glance-api.conf
  glanceapifilebak=/etc/glance/glance-api.conf.bak
  cp $glanceapifile $glanceapifilebak
  egrep -v "^#|^$"  $glanceapifilebak > $glanceapifile

  ops_add $glanceapifile database connection mysql+pymysql://glance:$PASS_DATABASE_GLANCE@$CTL1_IP_NIC2/glance

  ops_add $glanceapifile DEFAULT bind_host 0.0.0.0
  
  ops_add $glanceapifile keystone_authtoken www_authenticate_uri http://$CTL1_IP_NIC2:5000    
  ops_add $glanceapifile keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000
  ops_add $glanceapifile keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211    
  ops_add $glanceapifile keystone_authtoken auth_type password    
  ops_add $glanceapifile keystone_authtoken project_domain_name default
  ops_add $glanceapifile keystone_authtoken user_domain_name default
  ops_add $glanceapifile keystone_authtoken project_name service    
  ops_add $glanceapifile keystone_authtoken username glance
  ops_add $glanceapifile keystone_authtoken password $GLANCE_PASS

  ops_add $glanceapifile paste_deploy flavor keystone  

  ops_add $glanceapifile glance_store stores file,http    
  ops_add $glanceapifile glance_store default_store file    
  ops_add $glanceapifile glance_store filesystem_store_datadir /var/lib/glance/images/
}

## Function config /etc/glance/glance-registry.conf file
# function glance_config_registry () {
  # glanceregistryfile=/etc/glance/glance-registry.conf
  # glanceregistryfilebak=/etc/glance/glance-registry.conf.bak
  # cp $glanceregistryfile $glanceregistryfilebak
  # egrep -v "^#|^$"  $glanceregistryfilebak > $glanceregistryfile

  # ops_add $glanceregistryfile database connection mysql+pymysql://glance:$PASS_DATABASE_GLANCE@$CTL1_IP_NIC2/glance

  # ops_add $glanceregistryfile keystone_authtoken auth_uri http://$CTL1_IP_NIC2:5000
  # ops_add $glanceregistryfile keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000    
  # ops_add $glanceregistryfile keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211    
  # ops_add $glanceregistryfile keystone_authtoken auth_type password      
  # ops_add $glanceregistryfile keystone_authtoken project_domain_name default
  # ops_add $glanceregistryfile keystone_authtoken user_domain_name default    
  # ops_add $glanceregistryfile keystone_authtoken project_name service
  # ops_add $glanceregistryfile keystone_authtoken username glance
  # ops_add $glanceregistryfile keystone_authtoken password $GLANCE_PASS

  # ops_add $glanceregistryfile paste_deploy flavor keystone
# }

# Function populate the Image service database
function glance_populate_db () {
  echocolor "Populate the Image service database"
  sleep 3
  su -s /bin/sh -c "glance-manage db_sync" glance
}


# Function restart the Image services
function glance_restart () {
  echocolor "Restart the Image services"
  sleep 3

  # service glance-registry restart
  systemctl enable glance-api
  systemctl start glance-api
  
  sleep 10 
  systemctl restart glance-api
}

# Function upload image to Glance
function glance_upload_image () {
  echocolor "Upload image to Glance"
  sleep 3
  source /root/admin-openrc
  apt-get install wget -y
  wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

  openstack image create "cirros" \
    --file cirros-0.4.0-x86_64-disk.img \
    --disk-format qcow2 --container-format bare \
    --public
    
  openstack image list
}

#######################
###Execute functions###
#######################

sendtelegram "Thuc thi script $0 tren `hostname`"

# Create database for Glance
sendtelegram "Thuc thi glance_create_db tren `hostname`"
glance_create_db

# Create the Glance service credentials
sendtelegram "Thuc thi glance_create_service tren `hostname`"
glance_create_service

# Install components of Glance
sendtelegram "Thuc thi glance_install va glance_config_api tren `hostname`"
glance_install
glance_config_api

# Config /etc/glance/glance-registry.conf file
# sendtelegram "Thuc thi glance_config_registry tren `hostname`"
# glance_config_registry

# Populate the Image service database 
sendtelegram "Thuc thi glance_populate_db  tren `hostname`"
glance_populate_db

# Restart the Image services
sendtelegram "Thuc thi glance_restart tren `hostname`"
glance_restart 
  
# Upload image to Glance
sendtelegram "Thuc thi glance_upload_image tren `hostname`"
glance_upload_image

TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify

