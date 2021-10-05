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
GRANT ALL PRIVILEGES ON octavia.* TO octavia@'LOCALHOST' IDENTIFIED BY '$PASS_DATABASE_OCTAVIA'; 
GRANT ALL PRIVILEGES ON octavia.* TO octavia@'%' IDENTIFIED BY '$PASS_DATABASE_OCTAVIA'; 
FLUSH PRIVILEGES;
EOF
}

function octavia_user_endpoint() {

  openstack user create octavia --domain default --project service --password OCTAVIA_PASS 
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
  
  
  ops_add $ctl_octavia_conf api_settings bind_host $CTL1_IP_NIC
  ops_add $ctl_octavia_conf api_settings bind_port 9876
  ops_add $ctl_octavia_conf api_settings auth_strategy keystone
  ops_add $ctl_octavia_conf api_settings api_base_uri http://$CTL1_IP_NIC:9876
  
  ops_add $ctl_octavia_conf database connection mysql+pymysql://glance:$PASS_DATABASE_OCTAVIA@$CTL1_IP_NIC2/octavia
  
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

function octavia_make_cert() {

}