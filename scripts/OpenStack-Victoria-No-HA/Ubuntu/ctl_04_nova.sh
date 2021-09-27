#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

# Function create database for placement 
function placement_create_db () {
  echocolor "Create placement_create_db for placement"
  sleep 3

cat << EOF | mysql -uroot -p$PASS_DATABASE_ROOT
CREATE DATABASE placement;

GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NOVA_API';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '$PASS_DATABASE_NOVA_API';

FLUSH PRIVILEGES;
EOF
}

# Function create placement
function placement_create_info () {
  echocolor "Set environment variable for user admin"
  source /root/admin-openrc
  sleep 3

  ## Create info for placement user
  echocolor "Create info for placement user"
  sleep 3

  openstack user create --domain default --password $NOVA_PASS placement
  openstack role add --project service --user placement admin
  openstack service create --name placement  --description "Placement API" placement
  
  openstack endpoint create --region RegionOne placement public http://$CTL1_IP_NIC2:8778
  openstack endpoint create --region RegionOne placement internal http://$CTL1_IP_NIC2:8778
  openstack endpoint create --region RegionOne placement admin  http://$CTL1_IP_NIC2:8778

}

# Function install components of placement
function placement_install () {
  echocolor "Install and configure components of placement"
  sleep 3
  apt install -y placement-api
}

# Function config /etc/placement/placement.conf
function placement_config () {
  placementfile=/etc/placement/placement.conf
  placementfilebak=/etc/placement/placement.conf.bka
  cp $placementfile $placementfilebak
  egrep -v "^$|^#" $placementfilebak > $placementfile

  ops_add $placementfile placement_database connection mysql+pymysql://placement:$PASS_DATABASE_NOVA_API@$CTL1_IP_NIC2/placement
  ops_add $placementfile api auth_strategy keystone

  ops_add $placementfile keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000/v3
  ops_add $placementfile keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211
  ops_add $placementfile keystone_authtoken auth_type password
  ops_add $placementfile keystone_authtoken project_domain_name Default
  ops_add $placementfile keystone_authtoken user_domain_name Default
  ops_add $placementfile keystone_authtoken project_name service
  ops_add $placementfile keystone_authtoken username placement
  ops_add $placementfile keystone_authtoken password $NOVA_PASS
}

# Function populate the placement database
function placement_populate_db () {
echocolor "Populate the placement_populate_db database"
sleep 3

su -s /bin/sh -c "placement-manage db sync" placement
}

# Function restart installation
function placement_restart () {
  echocolor "Reload the web server"
  sleep 3

 service apache2 restart
}

##########################################################################################################
##########################################################################################################
##########################################################################################################

# Function create database for Nova
function nova_create_db () {
  echocolor "Create database for Nova"
  sleep 3

cat << EOF | mysql -uroot -p$PASS_DATABASE_ROOT
CREATE DATABASE nova_api;
CREATE DATABASE nova_cell0;
CREATE DATABASE nova;

GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NOVA_API';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$PASS_DATABASE_NOVA_API';
  
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NOVA';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$PASS_DATABASE_NOVA';

GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NOVA_CELL';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$PASS_DATABASE_NOVA_CELL';

FLUSH PRIVILEGES;
EOF
}

# Function create infomation for Compute service
function nova_create_info () {
  echocolor "Set environment variable for user admin"
  source /root/admin-openrc
  echocolor "Create infomation for Compute service"
  sleep 3

  ## Create info for nova user
  echocolor "Create info for nova user"
  sleep 3

  openstack user create --domain default --password $NOVA_PASS nova
  openstack role add --project service --user nova admin
  openstack service create --name nova --description "OpenStack Compute" compute
  openstack endpoint create --region RegionOne compute public http://$CTL1_IP_NIC2:8774/v2.1
  openstack endpoint create --region RegionOne compute internal http://$CTL1_IP_NIC2:8774/v2.1
  openstack endpoint create --region RegionOne compute admin http://$CTL1_IP_NIC2:8774/v2.1

}

# Function install components of Nova
function nova_install () {
  echocolor "Install and configure components of Nova"
  sleep 3
  apt install -y nova-api nova-conductor nova-novncproxy nova-scheduler
}

# Function config /etc/nova/nova.conf file
function nova_config () {
  novafile=/etc/nova/nova.conf
  novafilebak=/etc/nova/nova.conf.bak
  cp $novafile $novafilebak
  egrep -v "^$|^#" $novafilebak > $novafile

  ops_del $novafile api_database connection
  ops_add $novafile api_database connection mysql+pymysql://nova:$PASS_DATABASE_NOVA_API@$CTL1_IP_NIC2/nova_api

  ops_add $novafile database connection mysql+pymysql://nova:$PASS_DATABASE_NOVA@$CTL1_IP_NIC2/nova

  ops_add $novafile DEFAULT  transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC2

  ops_add $novafile api auth_strategy keystone

  ops_add $novafile keystone_authtoken www_authenticate_uri http://$CTL1_IP_NIC2:5000
  ops_add $novafile keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000
  ops_add $novafile keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211
  ops_add $novafile keystone_authtoken auth_type password
  ops_add $novafile keystone_authtoken project_domain_name default
  ops_add $novafile keystone_authtoken user_domain_name default
  ops_add $novafile keystone_authtoken project_name service
  ops_add $novafile keystone_authtoken username nova
  ops_add $novafile keystone_authtoken password $NOVA_PASS

  ops_add $novafile DEFAULT my_ip $CTL1_IP_NIC2
  ops_add $novafile DEFAULT use_neutron True
  ops_add $novafile DEFAULT irewall_driver nova.virt.firewall.NoopFirewallDriver
  ops_del $novafile DEFAULT log_dir


  ops_add $novafile vnc enabled true
  ops_add $novafile vnc vncserver_listen \$my_ip
  ops_add $novafile vnc vncserver_proxyclient_address \$my_ip

  ops_add $novafile glance api_servers http://$CTL1_IP_NIC2:9292
  
  ops_add $novafile cinder os_region_name RegionOne

  ops_add $novafile oslo_concurrency lock_path /var/lib/nova/tmp
    
  ops_add $novafile placement os_region_name RegionOne
  ops_add $novafile placement project_domain_name Default
  ops_add $novafile placement project_name service
  ops_add $novafile placement auth_type password
  ops_add $novafile placement user_domain_name Default
  ops_add $novafile placement auth_url http://$CTL1_IP_NIC2:5000/v3
  ops_add $novafile placement username placement
  ops_add $novafile placement password $PLACEMENT_PASS
  
  ops_add $novafile scheduler discover_hosts_in_cells_interval 300
  
}

# Function populate the nova-api database
nova_populate_nova_api_db () {
echocolor "Populate the nova-api database"
sleep 3
su -s /bin/sh -c "nova-manage api_db sync" nova
}

# Function register the cell0 database
nova_register_cell0 () {
  echocolor "Register the cell0 database"
  sleep 3
  su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
}

# Function create the cell1 cell
nova_create_cell1 () {
  echocolor "Create the cell1 cell"
  sleep 3
  su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
}

# Function populate the nova database
function nova_populate_nova_db () {
  echocolor "Populate the nova database"
  sleep 3
  su -s /bin/sh -c "nova-manage db sync" nova
}

# Function verify nova cell0 and cell1 are registered correctly
function nova_verify_cell () {
  echocolor "Verify nova cell0 and cell1 are registered correctly"
  sleep 3
  nova-manage cell_v2 list_cells
}

# Function restart installation
function nova_restart () {
  echocolor "Finalize installation"
  sleep 3

  service nova-api restart
  service nova-scheduler restart
  service nova-conductor restart
  service nova-novncproxy restart
  
  systemctl disable ufw
  systemctl stop ufw
}

#######################
## Execute placement_##
#######################
sendtelegram "Thuc thi script $0 tren `hostname`"

sendtelegram "Bat dau cai dat placement `hostname`"

placement_create_db
sendtelegram "Thuc thi placement_create_db tren `hostname`"

placement_create_info
sendtelegram "Thuc thi placement_create_info tren `hostname`"

placement_install
sendtelegram "Thuc thi placement_install tren `hostname`"

placement_config
sendtelegram "Thuc thi placement_config tren `hostname`"

placement_populate_db
sendtelegram "Thuc thi placement_populate_db tren `hostname`"

placement_restart
sendtelegram "Thuc thi placement_restart tren `hostname`"

sendtelegram "Da hoa thanh cai dat placement `hostname`"
notify


#######################
###Execute Nova###
#######################
sendtelegram "Thuc thi script $0 tren `hostname`"
sendtelegram "Bat dau cai dat Nova `hostname`"

# Create database for Nova
sendtelegram "Create database for Nova tren `hostname`"
nova_create_db

# Create infomation for Compute service
sendtelegram "Create infomation for Compute service tren `hostname`"
nova_create_info

# Install components of Nova
sendtelegram "Install components of Nova tren `hostname`"
nova_install

# Config /etc/nova/nova.conf file
sendtelegram "Cau hinh nova tren `hostname`"
nova_config


# Populate the nova-api database
sendtelegram "Populate the nova-api database tren `hostname`"
nova_populate_nova_api_db

# Register the cell0 database
sendtelegram "Register the cell0 database tren `hostname`"
nova_register_cell0

# Create the cell1 cell
sendtelegram "Create the cell1 cell tren `hostname`"
nova_create_cell1

# Populate the nova database
sendtelegram "Populate the nova database tren `hostname`"
nova_populate_nova_db

# Verify nova cell0 and cell1 are registered correctly
sendtelegram "Verify nova cell0 and cell1 are registered correctly tren `hostname`"
nova_verify_cell

# Restart installation
sendtelegram "Restart installation tren `hostname`"
nova_restart

TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify