yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables ipset

cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig
cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig


crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:Welcome789@10.24.44.171
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true

crudini --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://10.24.44.171:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://10.24.44.171:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name Default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name Default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password Welcome789

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf
modprobe br_netfilter

/sbin/sysctl -p

crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eth0
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $(ip addr show dev eth1 scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host 10.24.44.171
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret Welcome789

crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT force_metadata True

systemctl enable neutron-linuxbridge-agent.service
systemctl enable neutron-metadata-agent.service
systemctl enable neutron-dhcp-agent.service

systemctl start neutron-linuxbridge-agent.service
systemctl start neutron-metadata-agent.service
systemctl start neutron-dhcp-agent.service
systemctl restart openstack-nova-compute.service



