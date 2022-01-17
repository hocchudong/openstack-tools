#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

# Function create database for Octavia
function octavia_create_db () {

  echocolor "Create database for Octavia"
  sleep 3

cat << EOF | mysql -uroot -p$PASS_DATABASE_ROOT
CREATE DATABASE octavia; 
GRANT ALL PRIVILEGES ON octavia.* TO octavia@'localhost' IDENTIFIED BY '$PASS_DATABASE_OCTAVIA'; 
GRANT ALL PRIVILEGES ON octavia.* TO octavia@'%' IDENTIFIED BY '$PASS_DATABASE_OCTAVIA'; 
FLUSH PRIVILEGES;
EOF

}

function octavia_user_endpoint() {

  echocolor "Create octavia_user_endpoint for Octavia"
  openstack user create octavia --domain default --project service --password $OCTAVIA_PASS 
  openstack role add --project service --user octavia admin
  openstack service create --name octavia --description "OpenStack LBaaS" load-balancer

  openstack endpoint create --region RegionOne load-balancer public http://$CTL1_IP_NIC2:9876
  openstack endpoint create --region RegionOne load-balancer internal http://$CTL1_IP_NIC2:9876
  openstack endpoint create --region RegionOne load-balancer admin http://$CTL1_IP_NIC2:9876

}

function octavia_install_config() {

  echocolor "Cai dat octavia"
  sleep 3
  apt -y install octavia-api octavia-health-manager octavia-housekeeping octavia-worker
  apt -y install python3-octaviaclient
  
  ctl_octavia_conf=/etc/octavia/octavia.conf
  cp $ctl_octavia_conf $ctl_octavia_conf.orig
  
  mkdir -p /etc/octavia/certs/private
  mkdir ~/work
  cd ~/work
  git clone https://opendev.org/openstack/octavia.git -b stable/wallaby
  cd octavia/bin
   
  ./create_dual_intermediate_CA.sh
  cp -p ./dual_ca/etc/octavia/certs/server_ca.cert.pem /etc/octavia/certs
  cp -p ./dual_ca/etc/octavia/certs/server_ca-chain.cert.pem /etc/octavia/certs
  cp -p ./dual_ca/etc/octavia/certs/server_ca.key.pem /etc/octavia/certs/private
  cp -p ./dual_ca/etc/octavia/certs/client_ca.cert.pem /etc/octavia/certs
  cp -p ./dual_ca/etc/octavia/certs/client.cert-and-key.pem /etc/octavia/certs/private

  chown -R octavia /etc/octavia/certs
  
  ops_add $ctl_octavia_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC2
  
  
  ops_add $ctl_octavia_conf api_settings bind_host $CTL1_IP_NIC2
  ops_add $ctl_octavia_conf api_settings bind_port 9876
  ops_add $ctl_octavia_conf api_settings auth_strategy keystone
  ops_add $ctl_octavia_conf api_settings api_base_uri http://$CTL1_IP_NIC2:9876
  
  ops_add $ctl_octavia_conf database connection mysql+pymysql://octavia:$PASS_DATABASE_OCTAVIA@$CTL1_IP_NIC2/octavia
  
  ops_add $ctl_octavia_conf health_manager bind_ip 0.0.0.0
  ops_add $ctl_octavia_conf health_manager bind_port 5555
  
  ops_add $ctl_octavia_conf keystone_authtoken www_authenticate_uri http://$CTL1_IP_NIC2:5000
  ops_add $ctl_octavia_conf keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000
  ops_add $ctl_octavia_conf keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211
  ops_add $ctl_octavia_conf keystone_authtoken auth_type password
  ops_add $ctl_octavia_conf keystone_authtoken project_domain_name default
  ops_add $ctl_octavia_conf keystone_authtoken user_domain_name default
  ops_add $ctl_octavia_conf keystone_authtoken project_name service
  ops_add $ctl_octavia_conf keystone_authtoken username octavia
  ops_add $ctl_octavia_conf keystone_authtoken password $OCTAVIA_PASS
  
  ops_add $ctl_octavia_conf certificates ca_private_key /etc/octavia/certs/private/server_ca.key.pem
  ops_add $ctl_octavia_conf certificates ca_certificate /etc/octavia/certs/server_ca.cert.pem
  ops_add $ctl_octavia_conf certificates server_certs_key_passphrase insecure-key-do-not-use-this-key
  ops_add $ctl_octavia_conf certificates ca_private_key_passphrase not-secure-passphrase
  
  ops_add $ctl_octavia_conf haproxy_amphora server_ca /etc/octavia/certs/server_ca-chain.cert.pem
  ops_add $ctl_octavia_conf haproxy_amphora client_cert /etc/octavia/certs/private/client.cert-and-key.pem
  
  ops_add $ctl_octavia_conf controller_worker client_ca /etc/octavia/certs/client_ca.cert.pem

  ops_add $ctl_octavia_conf oslo_messaging topic octavia_prov
  
  ops_add $ctl_octavia_conf service_auth auth_url http://$CTL1_IP_NIC2:5000
  ops_add $ctl_octavia_conf service_auth memcached_servers $CTL1_IP_NIC2:11211
  ops_add $ctl_octavia_conf service_auth auth_type password
  ops_add $ctl_octavia_conf service_auth project_domain_name default
  ops_add $ctl_octavia_conf service_auth user_domain_name default
  ops_add $ctl_octavia_conf service_auth project_name service
  ops_add $ctl_octavia_conf service_auth username octavia
  ops_add $ctl_octavia_conf service_auth password $OCTAVIA_PASS
}

function octavia_create_policy() {

cat << EOF >/etc/octavia/policy.yaml 
# create new
"context_is_admin": "role:admin or role:load-balancer_admin"
"admin_or_owner": "is_admin:True or project_id:%(project_id)s"
"load-balancer:read": "rule:admin_or_owner"
"load-balancer:read-global": "is_admin:True"
"load-balancer:write": "rule:admin_or_owner"
"load-balancer:read-quota": "rule:admin_or_owner"
"load-balancer:read-quota-global": "is_admin:True"
"load-balancer:write-quota": "is_admin:True"
EOF

chmod 640 /etc/octavia/policy.yaml
chgrp octavia /etc/octavia/policy.yaml
}

function octavia_syn_db() {
  su -s /bin/bash octavia -c "octavia-db-manage --config-file /etc/octavia/octavia.conf upgrade head"
}

function octavia_restart() {
  systemctl restart octavia-api octavia-health-manager octavia-housekeeping octavia-worker
  systemctl enable octavia-api octavia-health-manager octavia-housekeeping octavia-worker
}

function octavia_image_create() {
  wget https://tarballs.opendev.org/openstack/octavia/test-images/test-only-amphora-x64-haproxy-ubuntu-focal.qcow2
  openstack image create "Amphora" --tag "Amphora" --file test-only-amphora-x64-haproxy-ubuntu-focal.qcow2 --disk-format qcow2 --container-format bare --private --project service

}

function octavia_create_flavor_sec() {

  openstack flavor create --id 100 --vcpus 1 --ram 1024 --disk 5 m1.octavia --private --project service

  openstack security group create lb-mgmt-sec-group --project service
  openstack security group rule create --protocol icmp --ingress lb-mgmt-sec-group
  openstack security group rule create --protocol tcp --dst-port 22:22 lb-mgmt-sec-group
  openstack security group rule create --protocol tcp --dst-port 80:80 lb-mgmt-sec-group

  openstack security group rule create --protocol tcp --dst-port 443:443 lb-mgmt-sec-group
  openstack security group rule create --protocol tcp --dst-port 9443:9443 lb-mgmt-sec-group
  
  # ID_ADMIN_PROJECT=`openstack project list | grep admin | awk '{print $2}'`
  # ID_SECURITY_GROUP=`openstack security group list | grep $ID_ADMIN_PROJECT | awk '{print $2}'`
  
  # openstack security group rule create --protocol tcp --dst-port 443:443 $ID_SECURITY_GROUP
  # openstack security group rule create --protocol tcp --dst-port 9443:9443 $ID_SECURITY_GROUP
    
}

function octavia_install_config_step2() {

  ctl_octavia_conf=/etc/octavia/octavia.conf

  ID_LB_MGMT_SEC_GROUP=`openstack security group list | egrep lb-mgmt-sec-group | awk '{print $2}'`
  ID_AMP_BOOT_NETWORK_LIST=`openstack network list | egrep provider | awk '{print $2}'`

  ops_add $ctl_octavia_conf controller_worker amp_image_tag Amphora
  ops_add $ctl_octavia_conf controller_worker amp_flavor_id 100
  ops_add $ctl_octavia_conf controller_worker amp_secgroup_list $ID_LB_MGMT_SEC_GROUP
  ops_add $ctl_octavia_conf controller_worker amp_boot_network_list $ID_AMP_BOOT_NETWORK_LIST
  ops_add $ctl_octavia_conf controller_worker network_driver allowed_address_pairs_driver
  ops_add $ctl_octavia_conf controller_worker compute_driver compute_nova_driver
  ops_add $ctl_octavia_conf controller_worker amphora_driver amphora_haproxy_rest_driver 
    

}

#######################
###Execute functions###
####################### 

sendtelegram "Thuc thi script $0 tren `hostname`"
sendtelegram "Cai OCTAVIA `hostname`"

source /root/admin-openrc
echocolor "Cai OCTAVIA `hostname`"

echocolor "Thuc thi octavia_create_db tren `hostname`"
sleep 3
sendtelegram "Thuc thi octavia_create_db tren `hostname`"
octavia_create_db

echocolor "Thuc thi octavia_user_endpoint tren `hostname`"
sleep 3
sendtelegram "Thuc thi octavia_user_endpoint tren `hostname`"
octavia_user_endpoint

echocolor "Thuc thi octavia_install_config tren `hostname`"
sleep 3
sendtelegram "Thuc thi octavia_install_config tren `hostname`"
octavia_install_config

echocolor "Thuc thi octavia_create_policy tren `hostname`"
sleep 3
sendtelegram "Thuc thi octavia_create_policy tren `hostname`"
octavia_create_policy

echocolor "Thuc thi octavia_restart tren `hostname`"
sleep 3
sendtelegram "Thuc thi octavia_syn_db va octavia_restart tren `hostname`"
octavia_syn_db
octavia_restart

echocolor "Thuc thi octavia_image_creat tren `hostname`"
sleep 3
sendtelegram "Thuc thi octavia_image_creat tren `hostname`"
octavia_image_create

echocolor "Thuc thi octavia_create_flavor_sec tren `hostname`"
sleep 3
sendtelegram "Thuc thi octavia_create_flavor_sec tren `hostname`"
octavia_create_flavor_sec
 
echocolor "Thuc thi octavia_install_config_step2 tren `hostname`"
sleep 3
sendtelegram "Thuc thi octavia_install_config_step2 octavia_restart tren `hostname`"
octavia_install_config_step2
octavia_restart
 
TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify


