mysql -uroot -pWelcome789 -e "CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'10.24.44.171' IDENTIFIED BY 'Welcome789';"


openstack user create neutron --domain default --password Welcome789

openstack role add --project service --user neutron admin

openstack service create --name neutron --description "OpenStack Compute" network

openstack endpoint create --region RegionOne network public http://10.24.44.171:9696

openstack endpoint create --region RegionOne network internal http://10.24.44.171:9696

openstack endpoint create --region RegionOne network admin http://10.24.44.171:9696

yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables 


cp  /etc/neutron/neutron.conf  /etc/neutron/neutron.conf.orig

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig

cp  /etc/neutron/plugins/ml2/linuxbridge_agent.ini  /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig 

cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig

cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig

crudini --set  /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set  /etc/neutron/neutron.conf DEFAULT service_plugins
crudini --set  /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:Welcome789@10.24.44.171
crudini --set  /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True 

crudini --set  /etc/neutron/neutron.conf database connection  mysql+pymysql://neutron:Welcome789@10.24.44.171/neutron

crudini --set  /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://10.24.44.171:5000
crudini --set  /etc/neutron/neutron.conf keystone_authtoken auth_url http://10.24.44.171:5000
crudini --set  /etc/neutron/neutron.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set  /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set  /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set  /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set  /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set  /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set  /etc/neutron/neutron.conf keystone_authtoken password Welcome789

crudini --set /etc/neutron/neutron.conf nova auth_url http://10.24.44.171:5000
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name Default
crudini --set /etc/neutron/neutron.conf nova user_domain_name Default
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password Welcome789

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security          
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000        
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True


crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eth0
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $(ip addr show dev eth1 scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver


echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf
modprobe br_netfilter
/sbin/sysctl -p


ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini


su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
	
systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
  
systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
	

