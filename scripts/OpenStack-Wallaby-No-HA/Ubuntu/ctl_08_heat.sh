#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

# Function create database for Heat
function heat_create_db () {

  echocolor "Create database for Heat"
  sleep 3

cat << EOF | mysql -uroot -p$PASS_DATABASE_ROOT
CREATE DATABASE heat; 
GRANT ALL PRIVILEGES ON heat.* TO heat@'localhost' IDENTIFIED BY '$PASS_DATABASE_HEAT'; 
GRANT ALL PRIVILEGES ON heat.* TO heat@'%' IDENTIFIED BY '$PASS_DATABASE_HEAT'; 
FLUSH PRIVILEGES;
EOF

}

function heat_user_endpoint() {

  openstack user create heat --domain default --project service --password $HEAT_PASS
  openstack role add --project service --user heat admin

  openstack service create --name heat --description "Openstack Orchestration" orchestration
  openstack service create --name heat-cfn --description "Openstack Orchestration" cloudformation

  openstack endpoint create --region RegionOne orchestration public http://$CTL1_IP_NIC2:8004/v1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne orchestration internal http://$CTL1_IP_NIC2:8004/v1/%\(tenant_id\)s
  openstack endpoint create --region RegionOne orchestration admin http://$CTL1_IP_NIC2:8004/v1/%\(tenant_id\)s
   
  openstack endpoint create --region RegionOne cloudformation public http://$CTL1_IP_NIC2:8000/v1
  openstack endpoint create --region RegionOne cloudformation internal http://$CTL1_IP_NIC2:8000/v1
  openstack endpoint create --region RegionOne cloudformation admin http://$CTL1_IP_NIC2:8000/v1

  openstack domain create --description "Stack projects and users" heat
  openstack user create heat_domain_admin --domain heat --password $HEAT_PASS

  openstack role add --domain heat --user heat_domain_admin admin

  openstack role create heat_stack_owner
  openstack role add --project admin --user admin heat_stack_owner

  openstack role create heat_stack_user

}

function heat_install_config() {
  echocolor "Cai dat heat"
  sleep 3
  
  apt -y install heat-api heat-api-cfn heat-engine python3-heatclient python3-vitrageclient python3-zunclient
  
  ctl_heat_config=/etc/heat/heat.conf
  cp $ctl_heat_config $ctl_heat_config.bka
  
  ops_add $ctl_heat_config DEFAULT deferred_auth_method trusts
  ops_add $ctl_heat_config DEFAULT trusts_delegated_roles heat_stack_owner
  ops_add $ctl_heat_config DEFAULT heat_metadata_server_url http://$CTL1_IP_NIC2:8000
  ops_add $ctl_heat_config DEFAULT heat_waitcondition_server_url  http://$CTL1_IP_NIC2:8000/v1/waitcondition
  ops_add $ctl_heat_config DEFAULT heat_watch_server_url http://10.0.0.50:8003
  ops_add $ctl_heat_config DEFAULT heat_stack_user_role heat_stack_user
  ops_add $ctl_heat_config DEFAULT stack_user_domain_name heat
  ops_add $ctl_heat_config DEFAULT stack_domain_admin heat_domain_admin 
  ops_add $ctl_heat_config DEFAULT stack_domain_admin_password $HEAT_PASS  
  
  
  
  ops_add $ctl_heat_config database connection  mysql+pymysql://heat:$PASS_DATABASE_HEAT@$CTL1_IP_NIC2/heat
  ops_add $ctl_heat_config transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC2
  
  ops_add $ctl_heat_config keystone_authtoken www_authenticate_uri http://$CTL1_IP_NIC2:5000
  ops_add $ctl_heat_config keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000
  ops_add $ctl_heat_config keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211
  ops_add $ctl_heat_config keystone_authtoken auth_type password
  ops_add $ctl_heat_config keystone_authtoken project_domain_name default
  ops_add $ctl_heat_config keystone_authtoken user_domain_name default
  ops_add $ctl_heat_config keystone_authtoken project_name service
  ops_add $ctl_heat_config keystone_authtoken username heat
  ops_add $ctl_heat_config keystone_authtoken password $HEAT_PASS  
  
  ops_add $ctl_heat_config clients_keystone auth_uri http://$CTL1_IP_NIC2:5000
  ops_add $ctl_heat_config ec2authtoken auth_uri http://$CTL1_IP_NIC2:5000
  
  ops_add $ctl_heat_config heat_api bind_host 0.0.0.0
  ops_add $ctl_heat_config heat_api bind_port  8004
  
  ops_add $ctl_heat_config heat_api_cfn bind_host 0.0.0.0
  ops_add $ctl_heat_config heat_api_cfn bind_port 8000
  
  ops_add $ctl_heat_config trustee auth_plugin password
  ops_add $ctl_heat_config trustee auth_url http://$CTL1_IP_NIC2:5000
  ops_add $ctl_heat_config trustee username heat
  ops_add $ctl_heat_config trustee password $HEAT_PASS
  ops_add $ctl_heat_config trustee user_domain_name default
  
}


function heat_syncdb() {
  chmod 640 /etc/heat/heat.conf
  chgrp heat /etc/heat/heat.conf
  su -s /bin/bash heat -c "heat-manage db_sync"
}


function heat_enable_restart() {
  systemctl restart heat-api heat-api-cfn heat-engine

}


#######################
###Execute functions###
####################### 

sendtelegram "Thuc thi script $0 tren `hostname`"
sendtelegram "Cai heat `hostname`"

source /root/admin-openrc
echocolor "Cai HEAT `hostname`"

echocolor "Thuc thi heat_create_db tren `hostname`"
heat_create_db

echocolor "Thuc thi heat_user_endpoint tren `hostname`"
heat_user_endpoint

echocolor "Thuc thi heat_install_config tren `hostname`"
heat_install_config

echocolor "Thuc thi heat_syncdb tren `hostname`"
heat_syncdb

echocolor "Thuc thi heat_enable_restart tren `hostname`"
heat_enable_restart
 
TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify


