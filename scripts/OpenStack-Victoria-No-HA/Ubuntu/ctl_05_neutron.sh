#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

# Function create database for Neutron
function neutron_create_db () {
  echocolor "Create database for Neutron"
  sleep 3

cat << EOF | mysql -uroot -p$PASS_DATABASE_ROOT
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NEUTRON';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$PASS_DATABASE_NEUTRON';
FLUSH PRIVILEGES;
EOF
}

# Function create the neutron service credentials
function neutron_create_info () {
  echocolor "Set environment variable for admin user"
  source /root/admin-openrc

  echocolor "Create the neutron service credentials"
  sleep 3

  openstack user create --domain default --password $NEUTRON_PASS neutron
  openstack role add --project service --user neutron admin
  openstack service create --name neutron  --description "OpenStack Networking" network
  openstack endpoint create --region RegionOne network public http://$CTL1_IP_NIC2:9696
  openstack endpoint create --region RegionOne network internal http://$CTL1_IP_NIC2:9696
  openstack endpoint create --region RegionOne network admin http://$CTL1_IP_NIC2:9696
}

# Function install the components
function neutron_install () {
  echocolor "Install the components"
  sleep 3
  apt install -y neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent
}

# Function configure the server component
function neutron_config_server_component () { 
  echocolor "Configure the server component"
  sleep 3
  neutronfile=/etc/neutron/neutron.conf
  neutronfilebak=/etc/neutron/neutron.conf.bak
  cp $neutronfile $neutronfilebak
  egrep -v "^$|^#" $neutronfilebak > $neutronfile

  ops_del $neutronfile database connection 
  ops_add $neutronfile database \
    connection mysql+pymysql://neutron:$PASS_DATABASE_NEUTRON@$CTL1_IP_NIC2/neutron

  ops_add $neutronfile DEFAULT core_plugin ml2
  ops_add $neutronfile DEFAULT service_plugins router
  ops_add $neutronfile DEFAULT allow_overlapping_ips true
  ops_add $neutronfile DEFAULT dhcp_agents_per_network 2


  ops_add $neutronfile DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC2
  ops_add $neutronfile DEFAULT auth_strategy keystone
  ops_add $neutronfile DEFAULT notify_nova_on_port_status_changes true
  ops_add $neutronfile DEFAULT notify_nova_on_port_data_changes true
  
  ops_add $neutronfile keystone_authtoken auth_uri http://$CTL1_IP_NIC2:5000
  ops_add $neutronfile keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000
  ops_add $neutronfile keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211
  ops_add $neutronfile keystone_authtoken auth_type password
  ops_add $neutronfile keystone_authtoken project_domain_name default
  ops_add $neutronfile keystone_authtoken user_domain_name default
  ops_add $neutronfile keystone_authtoken project_name service
  ops_add $neutronfile keystone_authtoken username neutron
  ops_add $neutronfile keystone_authtoken password $NEUTRON_PASS


  ops_add $neutronfile nova auth_url http://$CTL1_IP_NIC2:5000
  ops_add $neutronfile nova auth_type password
  ops_add $neutronfile nova project_domain_name default
  ops_add $neutronfile nova user_domain_name default
  ops_add $neutronfile nova region_name RegionOne
  ops_add $neutronfile nova project_name service
  ops_add $neutronfile nova username nova
  ops_add $neutronfile nova password $NOVA_PASS
}

# Function configure the Modular Layer 2 (ML2) plug-in
function neutron_config_ml2 () {
  echocolor "Configure the Modular Layer 2 (ML2) plug-in"
  sleep 3
  ml2file=/etc/neutron/plugins/ml2/ml2_conf.ini
  ml2filebak=/etc/neutron/plugins/ml2/ml2_conf.ini.bak
  cp $ml2file $ml2filebak
  egrep -v "^$|^#" $ml2filebak > $ml2file

  ops_add $ml2file ml2 type_drivers flat,vlan,vxlan
  ops_add $ml2file ml2 tenant_network_types vxlan
  ops_add $ml2file ml2 mechanism_drivers linuxbridge,l2population
  ops_add $ml2file ml2 extension_drivers port_security
  
  ops_add $ml2file ml2_type_flat flat_networks provider
  ops_add $ml2file ml2_type_vlan network_vlan_ranges provider
  ops_add $ml2file ml2_type_vxlan vni_ranges 1:1000
  
  ops_add $ml2file securitygroup enable_ipset true
}

# Function configure the Linux bridge agent
function neutron_config_linuxbridge () {
  echocolor "Configure the Linux bridge agent"
  sleep 3
  linuxbridgefile=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
  linuxbridgefilebak=/etc/neutron/plugins/ml2/linuxbridge_agent.ini.bak
  cp $linuxbridgefile $linuxbridgefilebak
  egrep -v "^$|^#" $linuxbridgefilebak > $linuxbridgefile

  ops_add $linuxbridgefile linux_bridge physical_interface_mappings provider:ens5
  ops_add $linuxbridgefile vxlan enable_vxlan true
  ops_add $linuxbridgefile vxlan local_ip $CTL1_IP_NIC2
  ops_add $linuxbridgefile vxlan l2_population true
  
  ops_add $linuxbridgefile securitygroup enable_security_group true
  ops_add $linuxbridgefile securitygroup \
    firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
}

function neutron_config_l3agent () {
  echocolor "Configure the L3 Agent"
  sleep 3
  l3agent=/etc/neutron/l3_agent.ini
  l3agentbak=/etc/neutron/l3_agent.ini.bak
  cp $l3agent $l3agentbak
  egrep -v "^$|^#" $l3agent > $l3agentbak

  ops_add $l3agent DEFAULT interface_driver linuxbridge

}


# Function configure the DHCP agent
function neutron_config_dhcp () {
  echocolor "Configure the DHCP agent"
  sleep 3
  dhcpfile=/etc/neutron/dhcp_agent.ini
  dhcpfilebak=/etc/neutron/dhcp_agent.ini.bak
  cp $dhcpfile $dhcpfilebak
  egrep -v "^$|^#" $dhcpfilebak > $dhcpfile

  ops_add $dhcpfile DEFAULT interface_driver linuxbridge
  ops_add $dhcpfile DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
  ops_add $dhcpfile DEFAULT enable_isolated_metadata true
}

# Function configure the metadata agent
function neutron_config_metadata () {
  echocolor "Configure the metadata agent"
  sleep 3
  metadatafile=/etc/neutron/metadata_agent.ini
  metadatafilebak=/etc/neutron/metadata_agent.ini.bak
  cp $metadatafile $metadatafilebak
  egrep -v "^$|^#" $metadatafilebak > $metadatafile

  ops_add $metadatafile DEFAULT nova_metadata_host $CTL1_IP_NIC2
  ops_add $metadatafile DEFAULT metadata_proxy_shared_secret $METADATA_SECRET
}

# Function configure the Compute service to use the Networking service
function neutron_config_compute_use_network () {
  echocolor "Configure the Compute service to use the Networking service"
  sleep 3
  novafile=/etc/nova/nova.conf

  ops_add $novafile neutron url http://$CTL1_IP_NIC2:9696
  ops_add $novafile neutron auth_url http://$CTL1_IP_NIC2:5000
  ops_add $novafile neutron auth_type password
  ops_add $novafile neutron project_domain_name default
  ops_add $novafile neutron user_domain_name default
  ops_add $novafile neutron region_name RegionOne
  ops_add $novafile neutron project_name service
  ops_add $novafile neutron username neutron
  ops_add $novafile neutron password $NEUTRON_PASS
  ops_add $novafile neutron service_metadata_proxy true
  ops_add $novafile neutron metadata_proxy_shared_secret $METADATA_SECRET
}

# Function populate the database
function neutron_populate_db () {
  echocolor "Populate the database"
  sleep 3
  su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
    --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
}

# Function restart installation
function neutron_restart () {
  echocolor "Neutron services restart "
  sleep 3
  service nova-api restart
  service neutron-server restart
  systemctl stop neutron-dhcp-agent
  systemctl stop neutron-metadata-agent
  
  systemctl disable neutron-dhcp-agent
  systemctl disable neutron-metadata-agent
  
  service neutron-linuxbridge-agent restart
  #service neutron-dhcp-agent restart
  #service neutron-metadata-agent restart
  #service neutron-l3-agent restart
}


#######################
###Execute functions###
#######################
sendtelegram "Thuc thi script $0 tren `hostname`"
sendtelegram "Cai NEUTRON `hostname`"

# Create database for Neutron
sendtelegram "Cai neutron_create_db tren `hostname`"
neutron_create_db

# Create the neutron service credentials
sendtelegram "Cai neutron_create_info tren `hostname`"
neutron_create_info

# Install the components
sendtelegram "Cai neutron_create_info tren `hostname`"
neutron_install

# Configure the server component
sendtelegram "Cai neutron_config_server_component tren `hostname`"
neutron_config_server_component

# Configure the Modular Layer 2 (ML2) plug-in
sendtelegram "Cai neutron_config_ml2 tren `hostname`"
neutron_config_ml2

# Configure the Linux bridge agent
sendtelegram "Cai neutron_config_linuxbridge tren `hostname`"
neutron_config_linuxbridge

# Configure the L3 Agent
sendtelegram "Cai neutron_config_l3agent tren `hostname`"
neutron_config_l3agent

# Configure the DHCP agent
# sendtelegram "Cai neutron_config_dhcp tren `hostname`"
#neutron_config_dhcp

# Configure the metadata agent
# sendtelegram "Cai neutron_config_metadata tren `hostname`"

#neutron_config_metadata

# Configure the Compute service to use the Networking service
sendtelegram "Cai neutron_config_compute_use_network tren `hostname`"
neutron_config_compute_use_network

# Populate the database
sendtelegram "Cai neutron_populate_db tren `hostname`"
neutron_populate_db

# Function restart installation
sendtelegram "Cai neutron_restart tren `hostname`"
neutron_restart

TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify
