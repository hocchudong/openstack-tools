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

function swift_create_db {
	mysql -uroot -p$PASS_DATABASE_ROOT  -e "CREATE DATABASE swift;
	GRANT ALL PRIVILEGES ON swift.* TO 'swift'@'localhost' IDENTIFIED BY '$PASS_DATABASE_SWIFT';
	GRANT ALL PRIVILEGES ON swift.* TO 'swift'@'%' IDENTIFIED BY '$PASS_DATABASE_SWIFT';
	GRANT ALL PRIVILEGES ON swift.* TO 'swift'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_SWIFT';

	FLUSH PRIVILEGES;"
}

function swift_user_endpoint {
	openstack user create  swift --domain default --password $SWIFT_PASS
	openstack role add --project service --user swift admin
	
	openstack service create --name swift --description "OpenStack Object Storage" object-store
	
	openstack endpoint create --region RegionOne object-store public http://$CTL1_IP_NIC1:8080/v1/AUTH_%\(tenant_id\)s
	openstack endpoint create --region RegionOne object-store internal http://$CTL1_IP_NIC1:8080/v1/AUTH_%\(tenant_id\)s
	openstack endpoint create --region RegionOne object-store admin http://$CTL1_IP_NIC1:8080/v1
}

function swift_install {
	echocolor "Cai dat swift"
	sleep 3
	yum -y install openstack-swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached
	ctl_swift_proxy_conf=/etc/swift/proxy-server.conf
	cp $ctl_swift_proxy_conf $ctl_swift_proxy_conf.orig
	
	curl -o /etc/swift/proxy-server.conf https://raw.githubusercontent.com/tigerlinux/openstack-newton-installer-centos7/master/libs/swift/proxy-server.conf

	ops_edit $ctl_swift_proxy_conf DEFAULT bind_port 8080
	ops_edit $ctl_swift_proxy_conf DEFAULT user swift
	ops_edit $ctl_swift_proxy_conf DEFAULT swift_dir /etc/swift
	
	ops_edit $ctl_swift_proxy_conf "pipeline:main" pipeline "catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server"
		
	ops_edit $ctl_swift_proxy_conf "app:proxy-server" use "egg:swift#proxy"
	ops_edit $ctl_swift_proxy_conf "app:proxy-server" account_autocreate true
	
	ops_edit $ctl_swift_proxy_conf "filter:keystoneauth" use "egg:swift#keystoneauth"
	ops_edit $ctl_swift_proxy_conf "filter:keystoneauth" operator_roles "admin,user"
	

	ops_edit $ctl_swift_proxy_conf "filter:authtoken" paste.filter_factory keystonemiddleware.auth_token:filter_factory
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" auth_uri http://$CTL1_IP_NIC1:5000
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" auth_url http://$CTL1_IP_NIC1:35357
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" memcached_servers $CTL1_IP_NIC1:11211
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" auth_type password
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" project_domain_name default
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" user_domain_name default
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" project_name service
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" username swift
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" password $SWIFT_PASS
	ops_edit $ctl_swift_proxy_conf "filter:authtoken" delay_auth_decision True
	
	ops_edit $ctl_swift_proxy_conf "filter:cache" use "egg:swift#memcache"
	ops_edit $ctl_swift_proxy_conf "filter:cache" memcache_servers $CTL1_IP_NIC1:11211
}


function swift_ring {

	cd /etc/swift
	swift-ring-builder account.builder create 10 3 1
	swift-ring-builder account.builder add --region 1 --zone 1 --ip $SWIFT1_IP_NIC1 --port 6202 --device sdb --weight 100
	swift-ring-builder account.builder add --region 1 --zone 1 --ip $SWIFT1_IP_NIC1 --port 6202 --device sdc --weight 100
	swift-ring-builder account.builder add --region 1 --zone 2 --ip $SWIFT2_IP_NIC1 --port 6202 --device sdb --weight 100
	swift-ring-builder account.builder add --region 1 --zone 2 --ip $SWIFT2_IP_NIC1 --port 6202 --device sdc --weight 100
	swift-ring-builder account.builder
	swift-ring-builder account.builder rebalance

	swift-ring-builder container.builder create 10 3 1
	swift-ring-builder container.builder add --region 1 --zone 1 --ip $SWIFT1_IP_NIC1 --port 6201 --device sdb --weight 100
	swift-ring-builder container.builder add --region 1 --zone 1 --ip $SWIFT1_IP_NIC1 --port 6201 --device sdc --weight 100
	swift-ring-builder container.builder add --region 1 --zone 2 --ip $SWIFT2_IP_NIC1 --port 6201 --device sdb --weight 100
	swift-ring-builder container.builder add --region 1 --zone 2 --ip $SWIFT2_IP_NIC1 --port 6201 --device sdc --weight 100
	swift-ring-builder container.builder
	swift-ring-builder container.builder rebalance

	swift-ring-builder object.builder create 10 3 1
	swift-ring-builder object.builder add --region 1 --zone 1 --ip $SWIFT1_IP_NIC1 --port 6200 --device sdb --weight 100
	swift-ring-builder object.builder add --region 1 --zone 1 --ip $SWIFT1_IP_NIC1 --port 6200 --device sdc --weight 100
	swift-ring-builder object.builder add --region 1 --zone 2 --ip $SWIFT2_IP_NIC1 --port 6200 --device sdb --weight 100
	swift-ring-builder object.builder add --region 1 --zone 2 --ip $SWIFT2_IP_NIC1 --port 6200 --device sdc --weight 100
	swift-ring-builder object.builder
	swift-ring-builder object.builder rebalance
	
	echocolor "Copy cac file sang node swift"
	scp /etc/swift/*.ring.gz root@$SWIFT1_IP_NIC1:/etc/swift
	scp /etc/swift/*.ring.gz root@$SWIFT2_IP_NIC1:/etc/swift
	cd /root/
}

function swift_config {
	curl -o /etc/swift/swift.conf https://raw.githubusercontent.com/tigerlinux/openstack-newton-installer-centos7/master/libs/swift/swift.conf

	ctl_swift_conf=/etc/swift/swift.conf
	cp $ctl_swift_conf $ctl_swift_conf.orig
	ops_edit $ctl_swift_conf  swift-hash swift_hash_path_suffix  $(openssl rand -hex 10)
	ops_edit $ctl_swift_conf  swift-hash swift_hash_path_prefix $(openssl rand -hex 10)
	ops_edit $ctl_swift_conf "storage-policy:0" name Policy-0
	ops_edit $ctl_swift_conf "storage-policy:0" default yes
	
	scp $ctl_swift_conf root@$SWIFT1_IP_NIC1:/etc/swift
	scp $ctl_swift_conf root@$SWIFT2_IP_NIC1:/etc/swift
	chown -R root:swift /etc/swift
	
	ssh root@$SWIFT1_IP_NIC1 'chown -R root:swift /etc/swift'		
	ssh root@$SWIFT2_IP_NIC1 'chown -R root:swift /etc/swift'		
}

function swift_enable_restart {
	systemctl enable openstack-swift-proxy.service memcached.service
	systemctl start openstack-swift-proxy.service memcached.service

	for IP_ADD in $SWIFT1_IP_NIC1 $SWIFT2_IP_NIC1
	do
	echocolor "Restart SWIFT tren tren $IP_ADD"
	sleep 3
ssh root@$IP_ADD << EOF

systemctl enable openstack-swift-account.service openstack-swift-account-auditor.service \
openstack-swift-account-reaper.service openstack-swift-account-replicator.service

systemctl start openstack-swift-account.service openstack-swift-account-auditor.service \
openstack-swift-account-reaper.service openstack-swift-account-replicator.service

systemctl enable openstack-swift-container.service \
openstack-swift-container-auditor.service openstack-swift-container-replicator.service \
openstack-swift-container-updater.service

systemctl start openstack-swift-container.service \
openstack-swift-container-auditor.service openstack-swift-container-replicator.service \
openstack-swift-container-updater.service

systemctl enable openstack-swift-object.service openstack-swift-object-auditor.service \
openstack-swift-object-replicator.service openstack-swift-object-updater.service

systemctl start openstack-swift-object.service openstack-swift-object-auditor.service \
openstack-swift-object-replicator.service openstack-swift-object-updater.service
init 6
EOF
done
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
source /root/admin-openrc
echocolor "Bat dau cai dat swift"

echocolor "Tao DB swift"
sleep 3
swift_create_db

echocolor "Tao user va endpoint cho swift"
sleep 3
swift_user_endpoint

echocolor "Cai dat va cau hinh swift"
sleep 3
swift_install

echocolor "Tao ring"
sleep 3
swift_ring

swift_config

echocolor "Restart dich vu swift"
sleep 3
swift_enable_restart

echocolor "Da cai dat xong swift"
