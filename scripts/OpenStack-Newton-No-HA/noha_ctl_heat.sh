#!/bin/bash -ex 
##############################################################################
### Script cai dat cac goi bo tro cho CTL

### Khai bao bien de thuc hien

source config.cfg

function echocolor {
	echo "#######################################################################"
	echo "$(tput setaf 3)##### $1 #####$(tput sgr0)"
	echo "#######################################################################"

}

function ops_edit {
	crudini --set "$1" "$2" "$3" "$4"
}

# Cach dung
## Cu phap:
##			ops_edit_file $bien_duong_dan_file [SECTION] [PARAMETER] [VALUAE]
## Vi du:
###			filekeystone=/etc/keystone/keystone.conf
###			ops_edit_file $filekeystone DEFAULT rpc_backend rabbit

# Ham de del mot dong trong file cau hinh
function ops_del {
	crudini --del "$1" "$2" "$3"
}

function heat_create_db {
	mysql -uroot -p$PASS_DATABASE_ROOT  -e "CREATE DATABASE heat;
	GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '$PASS_DATABASE_HEAT';
	GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '$PASS_DATABASE_HEAT';
	GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_HEAT';

	FLUSH PRIVILEGES;"
}

function heat_user_endpoint {
	openstack user create heat --domain default --password $HEAT_PASS
	openstack role add --project service --user heat admin
	openstack service create --name heat --description "Orchestration" orchestration
	openstack service create --name heat-cfn --description "Orchestration"  cloudformation

	openstack endpoint create --region RegionOne orchestration public http://$CTL1_IP_NIC1:8004/v1/%\(tenant_id\)s
	openstack endpoint create --region RegionOne orchestration internal http://$CTL1_IP_NIC1:8004/v1/%\(tenant_id\)s
	openstack endpoint create --region RegionOne orchestration admin http://$CTL1_IP_NIC1:8004/v1/%\(tenant_id\)s

	openstack endpoint create --region RegionOne cloudformation public http://$CTL1_IP_NIC1:8000/v1
	openstack endpoint create --region RegionOne cloudformation internal http://$CTL1_IP_NIC1:8000/v1
	openstack endpoint create --region RegionOne cloudformation admin http://$CTL1_IP_NIC1:8000/v1

	openstack domain create --description "Stack projects and users" heat
	openstack user create heat_domain_admin --domain heat --password $HEAT_DOMAIN_PASS
	openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
	openstack role create heat_stack_owner
	openstack role add --project demo --user demo heat_stack_owner
	openstack role create heat_stack_user
	
}

function heat_install_config {
	echocolor "Cai dat heat"
	sleep 3
	yum install -y openstack-heat-api openstack-heat-api-cfn openstack-heat-engine
	ctl_heat_conf=/etc/heat/heat.conf
	cp $ctl_heat_conf $ctl_heat_conf.orig


	ops_edit $ctl_heat_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC1
	ops_edit $ctl_heat_conf DEFAULT heat_metadata_server_url http://$CTL1_IP_NIC1:8000
	ops_edit $ctl_heat_conf DEFAULT heat_waitcondition_server_url http://$CTL1_IP_NIC1:8000/v1/waitcondition
	ops_edit $ctl_heat_conf DEFAULT stack_domain_admin heat_domain_admin
	ops_edit $ctl_heat_conf DEFAULT stack_domain_admin_password $HEAT_DOMAIN_PASS
	ops_edit $ctl_heat_conf DEFAULT stack_user_domain_name heat
	ops_edit $ctl_heat_conf DEFAULT rpc_backend rabbit
	
	ops_edit $ctl_heat_conf oslo_messaging_rabbit rabbit_host $CTL1_IP_NIC1
	ops_edit $ctl_heat_conf oslo_messaging_rabbit rabbit_port 5672
	ops_edit $ctl_heat_conf oslo_messaging_rabbit rabbit_userid openstack
	ops_edit $ctl_heat_conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS
	
	ops_edit $ctl_heat_conf database connection  mysql+pymysql://heat:$PASS_DATABASE_HEAT@$CTL1_IP_NIC1/heat

	ops_edit $ctl_heat_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
	ops_edit $ctl_heat_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
	ops_edit $ctl_heat_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
	ops_edit $ctl_heat_conf keystone_authtoken auth_type password
	ops_edit $ctl_heat_conf keystone_authtoken project_domain_name Default
	ops_edit $ctl_heat_conf keystone_authtoken user_domain_name Default
	ops_edit $ctl_heat_conf keystone_authtoken project_name service
	ops_edit $ctl_heat_conf keystone_authtoken username heat
	ops_edit $ctl_heat_conf keystone_authtoken password $HEAT_PASS

	ops_edit $ctl_heat_conf trustee auth_type password
	ops_edit $ctl_heat_conf trustee auth_url http://$CTL1_IP_NIC1:35357
	ops_edit $ctl_heat_conf trustee username heat
	ops_edit $ctl_heat_conf trustee password $HEAT_PASS
	ops_edit $ctl_heat_conf trustee user_domain_name default

	ops_edit $ctl_heat_conf clients_keystone auth_uri http://$CTL1_IP_NIC1:35357

	ops_edit $ctl_heat_conf ec2authtoken auth_uri http://$CTL1_IP_NIC1:5000

}

function heat_syncdb {
	su -s /bin/sh -c "heat-manage db_sync" heat

}

function heat_enable_restart {
	echocolor "Restart dich vu HEAT"
	sleep 3
	systemctl enable openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
	systemctl start openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service


}

############################
# Thuc thi cac functions
## Goi cac functions
############################
source /root/admin-openrc
echocolor "Bat dau cai dat HEAT"
echocolor "Tao DB HEAT"
sleep 3
heat_create_db

echocolor "Tao user va endpoint cho HEAT"
sleep 3
heat_user_endpoint

echocolor "Cai dat va cau hinh HEAT"
sleep 3
heat_install_config

echocolor "Dong bo DB cho HEAT"
sleep 3
heat_syncdb

echocolor "Restart dich vu HEAT"
sleep 3
heat_enable_restart

echocolor "Da cai dat xong HEAT"
