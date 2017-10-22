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
	crudini --set $1 $2 $3 $4
}

# Cach dung
## Cu phap:
##			ops_edit_file $bien_duong_dan_file [SECTION] [PARAMETER] [VALUAE]
## Vi du:
###			filekeystone=/etc/keystone/keystone.conf
###			ops_edit_file $filekeystone DEFAULT rpc_backend rabbit

# Ham de del mot dong trong file cau hinh
function ops_del {
	crudini --del $1 $2 $3
}

function cinder_create_db() {
	mysql -uroot -p$PASS_DATABASE_ROOT  -e "CREATE DATABASE cinder;
	GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$PASS_DATABASE_CINDER';
	GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$PASS_DATABASE_CINDER';
	GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_CINDER';

	FLUSH PRIVILEGES;"
}

function cinder_user_endpoint() {
	openstack user create  cinder --domain default --password $CINDER_PASS
	openstack role add --project service --user cinder admin

	openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
	openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

	openstack endpoint create --region RegionOne volumev2 public http://$CTL1_IP_NIC1:8776/v2/%\(tenant_id\)s
	openstack endpoint create --region RegionOne volumev2 internal http://$CTL1_IP_NIC1:8776/v2/%\(tenant_id\)s
	openstack endpoint create --region RegionOne volumev2 admin http://$CTL1_IP_NIC1:8776/v2/%\(tenant_id\)s

	openstack endpoint create --region RegionOne volumev3 public http://$CTL1_IP_NIC1:8776/v3/%\(tenant_id\)s
	openstack endpoint create --region RegionOne volumev3 internal http://$CTL1_IP_NIC1:8776/v3/%\(tenant_id\)s
	openstack endpoint create --region RegionOne volumev3 admin http://$CTL1_IP_NIC1:8776/v3/%\(tenant_id\)s


}

function cinder_install_config() {
	echocolor "Cai dat cinder"
	sleep 3
	yum -y install openstack-cinder targetcli
	ctl_cinder_conf=/etc/cinder/cinder.conf
	cp $ctl_cinder_conf $ctl_cinder_conf.orig

	if [ "$1" == "aio" ]; then
		ops_edit $ctl_cinder_conf DEFAULT rpc_backend rabbit
		ops_edit $ctl_cinder_conf DEFAULT auth_strategy keystone
		ops_edit $ctl_cinder_conf DEFAULT my_ip $CTL1_IP_NIC1
		ops_edit $ctl_cinder_conf DEFAULT control_exchange cinder
		ops_edit $ctl_cinder_conf DEFAULT osapi_volume_listen  \$my_ip
		ops_edit $ctl_cinder_conf DEFAULT control_exchange cinder
		ops_edit $ctl_cinder_conf DEFAULT glance_api_servers http://$CTL1_IP_NIC1:9292
		ops_edit $ctl_cinder_conf DEFAULT enabled_backends lvm

		ops_edit $ctl_cinder_conf database connection  mysql+pymysql://cinder:$PASS_DATABASE_CINDER@$CTL1_IP_NIC1/cinder

		ops_edit $ctl_cinder_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
		ops_edit $ctl_cinder_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
		ops_edit $ctl_cinder_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
		ops_edit $ctl_cinder_conf keystone_authtoken auth_type password
		ops_edit $ctl_cinder_conf keystone_authtoken project_domain_name Default
		ops_edit $ctl_cinder_conf keystone_authtoken user_domain_name Default
		ops_edit $ctl_cinder_conf keystone_authtoken project_name service
		ops_edit $ctl_cinder_conf keystone_authtoken username cinder
		ops_edit $ctl_cinder_conf keystone_authtoken password $CINDER_PASS

		ops_edit $ctl_cinder_conf oslo_messaging_rabbit rabbit_host $CTL1_IP_NIC1
		ops_edit $ctl_cinder_conf oslo_messaging_rabbit rabbit_port 5672
		ops_edit $ctl_cinder_conf oslo_messaging_rabbit rabbit_userid openstack
		ops_edit $ctl_cinder_conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS

		ops_edit $ctl_cinder_conf oslo_concurrency lock_path /var/lib/cinder/tmp

		ops_edit $ctl_cinder_conf oslo_messaging_notifications driver messagingv2


		ops_edit $ctl_cinder_conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
		ops_edit $ctl_cinder_conf lvm volume_group cinder-volumes
		ops_edit $ctl_cinder_conf lvm iscsi_protocol iscsi
		ops_edit $ctl_cinder_conf lvm iscsi_helper lioadm
	else
		ops_edit $ctl_cinder_conf DEFAULT rpc_backend rabbit
		ops_edit $ctl_cinder_conf DEFAULT auth_strategy keystone
		ops_edit $ctl_cinder_conf DEFAULT my_ip $CTL1_IP_NIC1
		ops_edit $ctl_cinder_conf DEFAULT control_exchange cinder
		ops_edit $ctl_cinder_conf DEFAULT osapi_volume_listen  \$my_ip
		ops_edit $ctl_cinder_conf DEFAULT control_exchange cinder
		ops_edit $ctl_cinder_conf DEFAULT glance_api_servers http://$CTL1_IP_NIC1:9292


		ops_edit $ctl_cinder_conf database connection  mysql+pymysql://cinder:$PASS_DATABASE_CINDER@$CTL1_IP_NIC1/cinder

		ops_edit $ctl_cinder_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
		ops_edit $ctl_cinder_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
		ops_edit $ctl_cinder_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
		ops_edit $ctl_cinder_conf keystone_authtoken auth_type password
		ops_edit $ctl_cinder_conf keystone_authtoken project_domain_name Default
		ops_edit $ctl_cinder_conf keystone_authtoken user_domain_name Default
		ops_edit $ctl_cinder_conf keystone_authtoken project_name service
		ops_edit $ctl_cinder_conf keystone_authtoken username cinder
		ops_edit $ctl_cinder_conf keystone_authtoken password $CINDER_PASS

		ops_edit $ctl_cinder_conf oslo_messaging_rabbit rabbit_host $CTL1_IP_NIC1
		ops_edit $ctl_cinder_conf oslo_messaging_rabbit rabbit_port 5672
		ops_edit $ctl_cinder_conf oslo_messaging_rabbit rabbit_userid openstack
		ops_edit $ctl_cinder_conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS

		ops_edit $ctl_cinder_conf oslo_concurrency lock_path /var/lib/cinder/tmp

		ops_edit $ctl_cinder_conf oslo_messaging_notifications driver messagingv2
	fi
}

function cinder_syncdb() {
	su -s /bin/sh -c "cinder-manage db sync" cinder

}

function cinder_enable_restart() {
	echocolor "Restart dich vu cinder"
	sleep 3
	if [ "$1" == "aio" ]; then
		systemctl enable openstack-cinder-api.service 
		systemctl enable openstack-cinder-scheduler.service 
		systemctl enable openstack-cinder-backup.service
		systemctl enable openstack-cinder-volume.service 
		systemctl enable target.service

		systemctl start openstack-cinder-api.service 
		systemctl start openstack-cinder-scheduler.service 
		systemctl start openstack-cinder-backup.service
		systemctl start openstack-cinder-volume.service 
		systemctl start  target.service 
	else
		systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service openstack-cinder-backup.service
		systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service openstack-cinder-backup.service
	fi
}

function create_lvm() {
	if [ "$1" == "aio" ]; then
		echocolor "Cai dat LVM"
		sleep 3
		yum -y install lvm2
		systemctl enable lvm2-lvmetad.service
		systemctl start lvm2-lvmetad.service

		pvcreate /dev/sdb
		vgcreate cinder-volumes /dev/sdb

		cp /etc/lvm/lvm.conf /etc/lvm/lvm.conf.orig
		#sed  -r -i 's#(filter = )(\[ "a/\.\*/" \])#\1["a\/sdb\/", "r/\.\*\/"]#g' /etc/lvm/lvm.conf
    # fix filter cua lvm tren CentOS 7.4, chen vao dong 141 cua file /etc/lvm/lvm.conf
    sed -i '141i\        filter = [ "a/sdb/", "r/.*/"]' /etc/lvm/lvm.conf
	else 
		echocolor "Khong cau hinh LVM vi ko cai cinder-volume"
	fi
	 
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
source /root/admin-openrc
echocolor "Bat dau cai dat CINDER"
create_lvm $1

echocolor "Tao DB CINDER"
sleep 3
cinder_create_db

echocolor "Tao user va endpoint cho CINDER"
sleep 3
cinder_user_endpoint

echocolor "Cai dat va cau hinh CINDER"
sleep 3
cinder_install_config $1

echocolor "Dong bo DB cho CINDER"
sleep 3
cinder_syncdb

echocolor "Restart dich vu CINDER"
sleep 3
cinder_enable_restart

echocolor "Da cai dat xong CINDER"
