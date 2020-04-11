mysql -uroot -pWelcome789 -e "CREATE DATABASE nova_api;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'10.24.44.171' IDENTIFIED BY 'Welcome789';

CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'10.24.44.171' IDENTIFIED BY 'Welcome789';

CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'10.24.44.171' IDENTIFIED BY 'Welcome789';
FLUSH PRIVILEGES;"

openstack user create nova --domain default --password Welcome789
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne compute public http://10.24.44.171:8774/v2.1

openstack endpoint create --region RegionOne compute internal http://10.24.44.171:8774/v2.1

openstack endpoint create --region RegionOne compute admin http://10.24.44.171:8774/v2.1

yum install -y openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler


crudini --set /etc/nova/nova.conf DEFAULT my_ip 10.24.44.171
crudini --set /etc/nova/nova.conf DEFAULT use_neutron true
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:Welcome789@10.24.44.171:5672/

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:Welcome789@10.24.44.171/nova_api
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:Welcome789@10.24.44.171/nova
crudini --set /etc/nova/nova.conf api connection  mysql+pymysql://nova:Welcome789@10.24.44.171/nova

crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://10.24.44.171:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://10.24.44.171:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password Welcome789

crudini --set /etc/nova/nova.conf vnc enabled true 
crudini --set /etc/nova/nova.conf vnc server_listen \$my_ip
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip

crudini --set /etc/nova/nova.conf glance api_servers http://10.24.44.171:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://10.24.44.171:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password Welcome789

crudini --set /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300

crudini --set /etc/nova/nova.conf neutron url http://10.24.44.171:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://10.24.44.171:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name Default
crudini --set /etc/nova/nova.conf neutron user_domain_name Default
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password Welcome789
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret Welcome789

su -s /bin/sh -c "nova-manage api_db sync" nova

su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

su -s /bin/sh -c "nova-manage db sync" nova

su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova


systemctl enable \
openstack-nova-api.service \
openstack-nova-scheduler.service \
openstack-nova-conductor.service \
openstack-nova-novncproxy.service

systemctl start \
  openstack-nova-api.service \
  openstack-nova-scheduler.service \
  openstack-nova-conductor.service \
  openstack-nova-novncproxy.service
	
openstack compute service list



