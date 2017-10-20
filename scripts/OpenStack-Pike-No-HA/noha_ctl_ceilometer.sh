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
##			ops_edit $bien_duong_dan_file [SECTION] [PARAMETER] [VALUAE]
## Vi du:
###			filekeystone=/etc/keystone/keystone.conf
###			ops_edit $filekeystone DEFAULT rpc_backend rabbit

# Ham de del mot dong trong file cau hinh
function ops_del {
    crudini --del "$1" "$2" "$3"
}

function aodh_create_db {
		mysql -uroot -p$PASS_DATABASE_ROOT  -e "CREATE DATABASE aodh;
		GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'localhost' IDENTIFIED BY '$PASS_DATABASE_AODH';
		GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'%' IDENTIFIED BY '$PASS_DATABASE_AODH';
		GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_AODH';
		FLUSH PRIVILEGES;"
}

function aodh_user_endpoint {
		openstack user create aodh --domain default --password $AODH_PASS
		openstack role add --project service --user aodh admin
		
		openstack service create --name aodh --description "Telemetry" alarming
		openstack endpoint create --region RegionOne alarming public http://$CTL1_IP_NIC1:8042
		openstack endpoint create --region RegionOne alarming internal http://$CTL1_IP_NIC1:8042
		openstack endpoint create --region RegionOne alarming admin http://$CTL1_IP_NIC1:8042
}

function aodh_install_config {
		echocolor "Cai dat AODH"
		sleep 3
		yum -y install openstack-aodh-api \
		openstack-aodh-evaluator openstack-aodh-notifier \
		openstack-aodh-listener openstack-aodh-expirer \
		python-aodhclient

		yum -y install mod_wsgi memcached python-memcached httpd install python-pip
		
		pip install requests-aws
		
		ctl_aodh_conf=/etc/aodh/aodh.conf
		cp $ctl_aodh_conf $ctl_aodh_conf.orig

		ops_edit $ctl_aodh_conf DEFAULT auth_strategy keystone
		ops_edit $ctl_aodh_conf DEFAULT my_ip $CTL1_IP_NIC1
		ops_edit $ctl_aodh_conf DEFAULT host `hostname`
		ops_edit $ctl_aodh_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC1
				
		ops_edit $ctl_aodh_conf database connection  mysql+pymysql://aodh:$PASS_DATABASE_AODH@$CTL1_IP_NIC1/aodh

		ops_edit $ctl_aodh_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
		ops_edit $ctl_aodh_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
		ops_edit $ctl_aodh_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
		ops_edit $ctl_aodh_conf keystone_authtoken auth_type password
		ops_edit $ctl_aodh_conf keystone_authtoken project_domain_name default
		ops_edit $ctl_aodh_conf keystone_authtoken user_domain_name default
		ops_edit $ctl_aodh_conf keystone_authtoken project_name service
		ops_edit $ctl_aodh_conf keystone_authtoken username aodh
		ops_edit $ctl_aodh_conf keystone_authtoken password $AODH_PASS
		
		ops_edit $ctl_aodh_conf service_credentials auth_type password
		ops_edit $ctl_aodh_conf service_credentials auth_url http://$CTL1_IP_NIC1:5000/v3
		ops_edit $ctl_aodh_conf service_credentials project_domain_name default
		ops_edit $ctl_aodh_conf service_credentials user_domain_name default
		ops_edit $ctl_aodh_conf service_credentials project_name service
		ops_edit $ctl_aodh_conf service_credentials username aodh
		ops_edit $ctl_aodh_conf service_credentials password $AODH_PASS
		ops_edit $ctl_aodh_conf service_credentials interface internalURL
		ops_edit $ctl_aodh_conf service_credentials region_name RegionOne
		
		ops_edit $ctl_aodh_conf api port 8042
		ops_edit $ctl_aodh_conf api host 0.0.0.0
		ops_edit $ctl_aodh_conf api paste_config api_paste.ini
		
		ops_edit $ctl_aodh_conf oslo_messaging_notifications driver messagingv2
		ops_edit $ctl_aodh_conf oslo_messaging_notifications topics notifications
}


function aodh_syncdb {
		aodh-dbsync --config-dir /etc/aodh/
}


function aodh_wsgi_config {
		cp -v ./files/wsgi-aodh.conf /etc/httpd/conf.d/wsgi-aodh.conf
		mkdir -p /var/www/cgi-bin/aodh
		cp -v ./files/aodh-app.wsgi /var/www/cgi-bin/aodh/app.wsgi
		cp -v ./files/aodh-api_paste.ini /etc/aodh/api_paste.ini
		chown -R aodh.aodh /etc/aodh/
		
		systemctl enable httpd
		systemctl stop memcached
		systemctl start memcached
		systemctl enable memcached
		systemctl stop httpd
		sleep 5
		systemctl start httpd
		sleep 5
}

function aodh_enable_restart {
		echocolor "Restart dich vu aodh"
		sleep 3
		systemctl stop openstack-aodh-api.service 
		systemctl disable openstack-aodh-api.service 

		systemctl enable \
		openstack-aodh-evaluator.service \
		openstack-aodh-notifier.service \
		openstack-aodh-listener.service

		systemctl start \
		openstack-aodh-evaluator.service \
		openstack-aodh-notifier.service \
		openstack-aodh-listener.service
}


function gnocchi_create_db {
		mysql -uroot -p$PASS_DATABASE_ROOT  -e "CREATE DATABASE gnocchi;
		GRANT ALL PRIVILEGES ON gnocchi.* TO 'gnocchi'@'localhost' IDENTIFIED BY '$PASS_DATABASE_GNOCCHI' WITH GRANT OPTION ;FLUSH PRIVILEGES;
		GRANT ALL PRIVILEGES ON gnocchi.* TO 'gnocchi'@'%' IDENTIFIED BY '$PASS_DATABASE_GNOCCHI' WITH GRANT OPTION ;FLUSH PRIVILEGES;
		GRANT ALL PRIVILEGES ON gnocchi.* TO 'gnocchi'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_GNOCCHI' WITH GRANT OPTION ;FLUSH PRIVILEGES;

		FLUSH PRIVILEGES;"
}


function gnocchi_ceilometer_user_endpoint {
		openstack user create ceilometer --domain default --password $CEILOMETER_PASS
		openstack role add --project service --user ceilometer admin
		openstack service create --name ceilometer --description "Telemetry" metering

		openstack role create ResellerAdmin
		openstack role add --project service --user ceilometer ResellerAdmin

		openstack user create gnocchi --domain default --password $GNOCCHI_PASS
		openstack role add --project service --user gnocchi admin
		openstack service create --name gnocchi --description "OpenStack Metric" metric

		openstack endpoint create --region RegionOne metric public http://$CTL1_IP_NIC1:8041
		openstack endpoint create --region RegionOne metric internal http://$CTL1_IP_NIC1:8041
		openstack endpoint create --region RegionOne metric admin http://$CTL1_IP_NIC1:8041
}

function gnocchi_ceilometer_install_config {
		# Khong cai Ceilometer API, hoc theo ban OpenStack Ocata
		yum -y install openstack-ceilometer-central \
		openstack-ceilometer-collector \
		openstack-ceilometer-common \
		openstack-ceilometer-compute \openstack-ceilometer-notification \
		python-ceilometerclient \
		python-ceilometer \
		python-ceilometerclient-doc \
		openstack-utils \
		openstack-selinux
		
		yum -y install openstack-gnocchi-api \
		openstack-gnocchi-common \
		openstack-gnocchi-indexer-sqlalchemy \
		openstack-gnocchi-metricd \
		openstack-gnocchi-statsd \
		python2-gnocchiclient
				
		ctl_ceilometer_conf=/etc/ceilometer/ceilometer.conf
		ctl_ceilometer_gnocchi_resources=/etc/ceilometer/gnocchi_resources.yaml
		cp $ctl_ceilometer_conf $ctl_ceilometer_conf.orig
		cp $ctl_ceilometer_gnocchi_resources $ctl_ceilometer_gnocchi_resources.orig
		
		ops_edit  $ctl_ceilometer_conf DEFAULT metering_api_port 8777
		ops_edit  $ctl_ceilometer_conf DEFAULT auth_strategy keystone
		ops_edit  $ctl_ceilometer_conf DEFAULT log_dir /var/log/ceilometer
		ops_edit  $ctl_ceilometer_conf DEFAULT host `hostname`
		ops_edit  $ctl_ceilometer_conf DEFAULT pipeline_cfg_file pipeline.yaml
		ops_edit  $ctl_ceilometer_conf DEFAULT hypervisor_inspector libvirt
		ops_edit  $ctl_ceilometer_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC1
		
		ops_edit  $ctl_ceilometer_conf DEFAULT dispatcher gnocchi
		ops_edit  $ctl_ceilometer_conf DEFAULT meter_dispatchers gnocchi
		ops_edit  $ctl_ceilometer_conf DEFAULT event_dispatchers gnocchi

		ops_edit  $ctl_ceilometer_conf DEFAULT nova_control_exchange nova
		ops_edit  $ctl_ceilometer_conf DEFAULT glance_control_exchange glance
		ops_edit  $ctl_ceilometer_conf DEFAULT neutron_control_exchange neutron
		ops_edit  $ctl_ceilometer_conf DEFAULT cinder_control_exchange cinder
		
		kvm_possible=`grep -E 'svm|vmx' /proc/cpuinfo|uniq|wc -l`
		forceqemu="no"
		if [ $forceqemu == "yes" ]
		then
			kvm_possible="0"
		fi

		if [ $kvm_possible == "0" ]
		then
			ops_edit  $ctl_ceilometer_conf DEFAULT libvirt_type qemu
		else
			ops_edit  $ctl_ceilometer_conf DEFAULT libvirt_type kvm
		fi

		ops_edit  $ctl_ceilometer_conf DEFAULT debug false
		ops_edit  $ctl_ceilometer_conf DEFAULT notification_topics notifications
		
		ops_edit  $ctl_ceilometer_conf DEFAULT heat_control_exchange heat
		ops_edit  $ctl_ceilometer_conf DEFAULT control_exchange ceilometer
		ops_edit  $ctl_ceilometer_conf DEFAULT http_control_exchanges nova
		
		# ops_edit  $ctl_ceilometer_conf oslo_messaging_rabbit rabbit_host $CTL1_IP_NIC1
		# ops_edit  $ctl_ceilometer_conf oslo_messaging_rabbit rabbit_port 5672
		# ops_edit  $ctl_ceilometer_conf oslo_messaging_rabbit rabbit_userid openstack
		# ops_edit  $ctl_ceilometer_conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS
		
		ops_edit  $ctl_ceilometer_conf keystone_authtoken admin_tenant_name service
		ops_edit  $ctl_ceilometer_conf keystone_authtoken admin_user ceilometer
		ops_edit  $ctl_ceilometer_conf keystone_authtoken admin_password $CEILOMETER_PASS
		ops_edit  $ctl_ceilometer_conf keystone_authtoken auth_type password
		ops_edit  $ctl_ceilometer_conf keystone_authtoken username ceilometer
		ops_edit  $ctl_ceilometer_conf keystone_authtoken password $CEILOMETER_PASS
		ops_edit  $ctl_ceilometer_conf keystone_authtoken project_domain_name Default
		ops_edit  $ctl_ceilometer_conf keystone_authtoken user_domain_name Default
		ops_edit  $ctl_ceilometer_conf keystone_authtoken project_name service

		ops_edit  $ctl_ceilometer_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
		ops_edit  $ctl_ceilometer_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
		ops_edit  $ctl_ceilometer_conf keystone_authtoken signing_dir '/var/lib/ceilometer/tmp-signing'
		ops_edit  $ctl_ceilometer_conf keystone_authtoken auth_version v3
		ops_edit  $ctl_ceilometer_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211

		ops_edit  $ctl_ceilometer_conf service_credentials os_username ceilometer
		ops_edit  $ctl_ceilometer_conf service_credentials os_password $CEILOMETER_PASS
		ops_edit  $ctl_ceilometer_conf service_credentials os_tenant_name service
		ops_edit  $ctl_ceilometer_conf service_credentials os_auth_url http://$CTL1_IP_NIC1:5000/v3
		ops_edit  $ctl_ceilometer_conf service_credentials os_region_name RegionOne
		ops_edit  $ctl_ceilometer_conf service_credentials os_endpoint_type internalURL
		ops_edit  $ctl_ceilometer_conf service_credentials region_name RegionOne
		ops_edit  $ctl_ceilometer_conf service_credentials interface internal
		ops_edit  $ctl_ceilometer_conf service_credentials auth_type password

		ops_edit  $ctl_ceilometer_conf service_credentials username ceilometer
		ops_edit  $ctl_ceilometer_conf service_credentials password $CEILOMETER_PASS
		ops_edit  $ctl_ceilometer_conf service_credentials auth_url http://$CTL1_IP_NIC1:5000/v3
		ops_edit  $ctl_ceilometer_conf service_credentials project_domain_name default
		ops_edit  $ctl_ceilometer_conf service_credentials user_domain_name default
		ops_edit  $ctl_ceilometer_conf service_credentials project_name service

		# End of Keystone Section
		
		ops_edit  $ctl_ceilometer_conf collector workers 2
		ops_edit  $ctl_ceilometer_conf notification workers 2

		ops_edit  $ctl_ceilometer_conf publisher telemetry_secret fe01a6ed3e04c4be1cd8

		ops_edit  $ctl_ceilometer_conf alarm evaluation_service ceilometer.alarm.service.SingletonAlarmService
		ops_edit  $ctl_ceilometer_conf alarm partition_rpc_topic alarm_partition_coordination

		ops_edit  $ctl_ceilometer_conf api port 8777
		ops_edit  $ctl_ceilometer_conf api host 0.0.0.0
		ops_edit  $ctl_ceilometer_conf api auth_mode keystone

		sed -r -i 's/http_control_exchanges\ =\ nova/http_control_exchanges\ =\ nova\nhttp_control_exchanges\ =\ glance\nhttp_control_exchanges\ =\ cinder\nhttp_control_exchanges\ =\ neutron\n/'  $ctl_ceilometer_conf

		ops_edit  $ctl_ceilometer_conf service_types neutron network
		ops_edit  $ctl_ceilometer_conf service_types nova compute
		ops_edit  $ctl_ceilometer_conf service_types swift object-store
		ops_edit  $ctl_ceilometer_conf service_types glance image
		crudini --del  $ctl_ceilometer_conf service_types kwapi
		ops_edit  $ctl_ceilometer_conf service_types neutron_lbaas_version v2

		ops_edit  $ctl_ceilometer_conf oslo_messaging_notifications topics notifications
		ops_edit  $ctl_ceilometer_conf oslo_messaging_notifications driver messagingv2
		ops_edit  $ctl_ceilometer_conf exchange_control heat_control_exchange heat
		ops_edit  $ctl_ceilometer_conf exchange_control glance_control_exchange glance
		ops_edit  $ctl_ceilometer_conf exchange_control keystone_control_exchange keystone
		ops_edit  $ctl_ceilometer_conf exchange_control cinder_control_exchange cinder
		ops_edit  $ctl_ceilometer_conf exchange_control sahara_control_exchange sahara
		ops_edit  $ctl_ceilometer_conf exchange_control swift_control_exchange swift
		ops_edit  $ctl_ceilometer_conf exchange_control magnum_control_exchange magnum
		ops_edit  $ctl_ceilometer_conf exchange_control trove_control_exchange trove
		ops_edit  $ctl_ceilometer_conf exchange_control nova_control_exchange nova
		ops_edit  $ctl_ceilometer_conf exchange_control neutron_control_exchange neutron
		ops_edit  $ctl_ceilometer_conf publisher_notifier telemetry_driver messagingv2
		ops_edit  $ctl_ceilometer_conf publisher_notifier metering_topic metering
		ops_edit  $ctl_ceilometer_conf publisher_notifier event_topic event
		
		# Khai bao cau hinh cho ceilometer khi su dung gnocchi
		ops_edit  $ctl_ceilometer_conf dispatcher_gnocchi url http://$CTL1_IP_NIC1:8041
		ops_edit  $ctl_ceilometer_conf dispatcher_gnocchi filter_service_activity False
		ops_edit  $ctl_ceilometer_conf dispatcher_gnocchi archive_policy low
		ops_edit  $ctl_ceilometer_conf dispatcher_gnocchi resources_definition_file gnocchi_resources.yaml

		mkdir -p /var/lib/ceilometer/tmp-signing
		chown ceilometer.ceilometer /var/lib/ceilometer/tmp-signing
		chmod 700 /var/lib/ceilometer/tmp-signing

		############### Cau hinh cho Gnocchi 
		ctl_gnocchi_json=/etc/gnocchi/policy.json
		ctl_gnocchi_conf=/etc/gnocchi/gnocchi.conf
		cp $ctl_gnocchi_json $ctl_gnocchi_json.orig
		cp $ctl_gnocchi_conf $ctl_gnocchi_conf.orig
		cp ./files/gnocchi-api-paste.ini /etc/gnocchi/api-paste.ini		
		
		ops_edit $ctl_gnocchi_conf DEFAULT debug false
		ops_edit $ctl_gnocchi_conf DEFAULT log_file /var/log/gnocchi/gnocchi.log

		ops_edit $ctl_gnocchi_conf api host 0.0.0.0
		ops_edit $ctl_gnocchi_conf api port 8041
		ops_edit $ctl_gnocchi_conf api paste_config /etc/gnocchi/api-paste.ini
		ops_edit $ctl_gnocchi_conf api auth_mode keystone

		ops_edit $ctl_gnocchi_conf database connection mysql+pymysql://gnocchi:$PASS_DATABASE_GNOCCHI@$CTL1_IP_NIC1/gnocchi
		ops_edit $ctl_gnocchi_conf indexer url mysql+pymysql://gnocchi:$PASS_DATABASE_GNOCCHI@$CTL1_IP_NIC1/gnocchi

		ops_edit $ctl_gnocchi_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000/v3
		ops_edit $ctl_gnocchi_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357/v3
		ops_edit $ctl_gnocchi_conf keystone_authtoken auth_type password
		ops_edit $ctl_gnocchi_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
		ops_edit $ctl_gnocchi_conf keystone_authtoken project_domain_name Default
		ops_edit $ctl_gnocchi_conf keystone_authtoken user_domain_name Default
		ops_edit $ctl_gnocchi_conf keystone_authtoken project_name service
		ops_edit $ctl_gnocchi_conf keystone_authtoken username gnocchi
		ops_edit $ctl_gnocchi_conf keystone_authtoken password $GNOCCHI_PASS
		ops_edit $ctl_gnocchi_conf keystone_authtoken interface internalURL
		ops_edit $ctl_gnocchi_conf keystone_authtoken region_name RegionOne

		ops_edit $ctl_gnocchi_conf service_credentials auth_uri http://$CTL1_IP_NIC1:5000/v3
		ops_edit $ctl_gnocchi_conf service_credentials auth_url http://$CTL1_IP_NIC1:35357/v3
		ops_edit $ctl_gnocchi_conf service_credentials auth_type password
		ops_edit $ctl_gnocchi_conf service_credentials memcached_servers $CTL1_IP_NIC1:11211
		ops_edit $ctl_gnocchi_conf service_credentials project_domain_name Default
		ops_edit $ctl_gnocchi_conf service_credentials user_domain_name Default
		ops_edit $ctl_gnocchi_conf service_credentials project_name service
		ops_edit $ctl_gnocchi_conf service_credentials username gnocchi
		ops_edit $ctl_gnocchi_conf service_credentials password $GNOCCHI_PASS
		ops_edit $ctl_gnocchi_conf service_credentials interface internalURL
		ops_edit $ctl_gnocchi_conf service_credentials region_name RegionOne

		ops_edit $ctl_gnocchi_conf storage driver file
		ops_edit $ctl_gnocchi_conf storage file_basepath '/var/lib/gnocchi'
		ops_edit $ctl_gnocchi_conf storage coordination_url 'file:///var/lib/gnocchi/locks'

		ops_edit $ctl_gnocchi_conf indexer driver sqlalchemy
		ops_edit $ctl_gnocchi_conf archive_policy default_aggregation_methods 'mean,min,max,sum,std,median,count,last,95pct'
		
		chown -R gnocchi.gnocchi /var/log/gnocchi/
		chown -R gnocchi.gnocchi /etc/gnocchi/
		su gnocchi -s /bin/sh -c 'gnocchi-upgrade --config-file /etc/gnocchi/gnocchi.conf'
		#su gnocchi -s /bin/sh -c 'gnocchi-upgrade --config-file /etc/gnocchi/gnocchi.conf --create-legacy-resource-types'

		systemctl stop openstack-gnocchi-api
		systemctl disable openstack-gnocchi-api
}


function gnocchi_wsgi_config {


		wget -O /etc/httpd/conf.d/wsgi-gnocchi.conf https://raw.githubusercontent.com/tigerlinux/openstack-ocata-installer-centos7/master/libs/gnocchi/wsgi-gnocchi.conf 

		mkdir -p /var/www/cgi-bin/gnocchi

		wget -O /var/www/cgi-bin/gnocchi/app.wsgi https://raw.githubusercontent.com/tigerlinux/openstack-ocata-installer-centos7/master/libs/gnocchi/app.wsgi 
		
		chown -R gnocchi.gnocchi /var/log/gnocchi/
		chown -R gnocchi.gnocchi /etc/gnocchi/
		systemctl enable httpd
		systemctl stop httpd
		sleep 5
		systemctl restart httpd
}

function gnocchi_ceilometer_enable_restart {
		ceilometer-upgrade --skip-metering-database

		systemctl start openstack-gnocchi-metricd
		systemctl enable openstack-gnocchi-metricd

		systemctl start openstack-ceilometer-central
		systemctl enable openstack-ceilometer-central

		systemctl start openstack-ceilometer-collector
		systemctl enable openstack-ceilometer-collector

		systemctl start openstack-ceilometer-notification
		systemctl enable openstack-ceilometer-notification

		systemctl disable openstack-ceilometer-polling > /dev/null 2>&1
}


function enable_ceilometer_for_services {
		 #cinder-volume-usage-audit  --start_time='YYYY-MM-DD HH:MM:SS' --end_time='YYYY-MM-DD HH:MM:SS' --send_actions
		 systemctl restart openstack-cinder-api.service openstack-cinder-scheduler.service
		 systemctl restart openstack-cinder-volume.service
		 
		 ops_edit /etc/neutron/neutron.conf oslo_messaging_notifications driver messagingv2
		 systemctl restart neutron-server.service
		 
		 

}

############################
# Thuc thi cac functions
## Goi cac functions
############################
echocolor "Bat dau cai dat AODH"

echocolor "Tao DB AODH"
sleep 3
aodh_create_db

echocolor "Tao user va endpoint cho AODH"
sleep 3
aodh_user_endpoint

echocolor "Cai dat va cau hinh AODH"
sleep 3
aodh_install_config

echocolor "Dong bo DB cho AODH"
## Chi dong do neu AODH su dung SQL DATABASE de luu metric
sleep 3
aodh_syncdb

echocolor "Cau hinh WSGI cho AODH"
sleep 3
aodh_wsgi_config

echocolor "Restart dich vu AODH"
sleep 3
aodh_enable_restart
echocolor "Da cai dat xong AODH"

########### Cai dat  va cau hinh Ceilometer - Gnocchi
echocolor "Bat dau cai dat Ceilometer & Gnocchi"
echocolor "Tao DB Ceilometer & Gnocchi"
sleep 3
gnocchi_create_db

echocolor "Tao user va endpoint cho Ceilometer & Gnocchi"
sleep 3
gnocchi_ceilometer_user_endpoint

echocolor "Cai dat va cau hinh Ceilometer & Gnocchi"
sleep 3
gnocchi_ceilometer_install_config

echocolor "Cau hinh WSGI cho Ceilometer & Gnocchi"
sleep 3
gnocchi_wsgi_config

echocolor "Restart dich vu Ceilometer & Gnocchi"
sleep 3
gnocchi_ceilometer_enable_restart
echocolor "Da cai dat xong Ceilometer & Gnocchi"

enable_ceilometer_for_services
