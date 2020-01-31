#!/bin/bash -ex 
##############################################################################
### Script cai dat cac goi bo tro cho CTL

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
my_ip=$(ip addr show dev ens160 scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
function ops_del {
	crudini --del $1 $2 $3
}

function swift_prepare {
	echocolor "Cai dat swift"
	sleep 3
	yum -y install xfsprogs rsync
	
	mkfs.xfs /dev/sdb
	mkfs.xfs /dev/sdc
	mkdir -p /srv/node/sdb
	mkdir -p /srv/node/sdc
	
	echo "/dev/sdb /srv/node/sdb xfs noatime,nodiratime,nobarrier,logbufs=8 0 2" >> /etc/fstab
	echo "/dev/sdc /srv/node/sdc xfs noatime,nodiratime,nobarrier,logbufs=8 0 2" >> /etc/fstab
	
	mount /srv/node/sdb
	mount /srv/node/sdc
	
echo 'uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = MANAGEMENT_INTERFACE_IP_ADDRESS

[account]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/object.lock' >>  /etc/rsyncd.conf

	sed -i -e "s/MANAGEMENT_INTERFACE_IP_ADDRESS/$my_ip/g" /etc/rsyncd.conf
	
	systemctl enable rsyncd.service
	systemctl start rsyncd.service
}

function swift_install {
	yum -y install openstack-swift-account openstack-swift-container \
  openstack-swift-object
	
	curl -o /etc/swift/account-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/account-server.conf-sample?h=stable/newton
	curl -o /etc/swift/container-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/container-server.conf-sample?h=stable/newton
	curl -o /etc/swift/object-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/object-server.conf-sample?h=stable/newton
	
	swift_account_conf=/etc/swift/account-server.conf
	swift_container_conf=/etc/swift/container-server.conf
	swift_object_conf=/etc/swift/object-server.conf
	cp $swift_account_conf $swift_account_conf.orig
	cp $swift_container_conf $swift_container_conf.orig
	cp $swift_object_conf $swift_object_conf.orig
	
	## Cau hinh cho file /etc/swift/account-server.conf
	ops_edit $swift_account_conf DEFAULT bind_ip $my_ip
	ops_edit $swift_account_conf DEFAULT bind_port 6202
	ops_edit $swift_account_conf DEFAULT user swift
	ops_edit $swift_account_conf DEFAULT swift_dir /etc/swift
	ops_edit $swift_account_conf DEFAULT devices /srv/node
	ops_edit $swift_account_conf DEFAULT mount_check True
	
	ops_edit $swift_account_conf "pipeline:main" pipeline "healthcheck recon account-server"
	
	ops_edit $swift_account_conf "filter:recon" use "egg:swift#recon"
	ops_edit $swift_account_conf "filter:recon" recon_cache_path /var/cache/swift
	
	## Cau hinh cho file /etc/swift/container-server.conf
	ops_edit $swift_container_conf DEFAULT bind_ip $my_ip
	ops_edit $swift_container_conf DEFAULT bind_port 6201
	ops_edit $swift_container_conf DEFAULT user swift
	ops_edit $swift_container_conf DEFAULT swift_dir /etc/swift
	ops_edit $swift_container_conf DEFAULT devices /srv/node
	ops_edit $swift_container_conf DEFAULT mount_check True
	
	ops_edit $swift_container_conf "pipeline:main" pipeline "healthcheck recon container-server"
	
	ops_edit $swift_container_conf "filter:recon" use "egg:swift#recon"
	ops_edit $swift_container_conf "filter:recon" recon_cache_path /var/cache/swift
	
	## Cau hinh cho file /etc/swift/object-server.conf
	ops_edit $swift_object_conf DEFAULT bind_ip $my_ip
	ops_edit $swift_object_conf DEFAULT bind_port 6200
	ops_edit $swift_object_conf DEFAULT user swift
	ops_edit $swift_object_conf DEFAULT swift_dir /etc/swift
	ops_edit $swift_object_conf DEFAULT devices /srv/node
	ops_edit $swift_object_conf DEFAULT mount_check True
	
	ops_edit $swift_object_conf "pipeline:main" pipeline "healthcheck recon object-server "
	
	ops_edit $swift_object_conf "filter:recon" use "egg:swift#recon"
	ops_edit $swift_object_conf "filter:recon" recon_cache_path /var/cache/swift
	ops_edit $swift_object_conf "filter:recon" recon_lock_path /var/lock
	
	chown -R swift:swift /srv/node
	mkdir -p /var/cache/swift
	chown -R root:swift /var/cache/swift
	chmod -R 775 /var/cache/swift
}

##############################################################################
# Thuc thi cac functions
## Goi cac functions
##############################################################################
echocolor "Thuc thi cac script cai dat tren may chu Swift"
echocolor "Cai dat cac goi chuan bi va phan vung o cung tren may chu Swift"
sleep 3
swift_prepare

echocolor "Cai dat va cau hinh Swift"
sleep 3
swift_install

