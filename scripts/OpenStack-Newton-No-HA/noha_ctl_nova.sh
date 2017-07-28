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

function nova_create_db {
      mysql -uroot -p$PASS_DATABASE_ROOT -e "CREATE DATABASE nova_api;
      GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NOVA_API';
      GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$PASS_DATABASE_NOVA_API';
      GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_NOVA_API';

      CREATE DATABASE nova;
      GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NOVA';
      GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$PASS_DATABASE_NOVA';
      GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_NOVA';
      FLUSH PRIVILEGES;"
}

function nova_user_endpoint {
        openstack user create  nova --domain default --password $NOVA_PASS
        openstack role add --project service --user nova admin
        openstack service create --name nova --description "OpenStack Compute" compute
        openstack endpoint create --region RegionOne compute public http://$CTL1_IP_NIC1:8774/v2.1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne compute internal http://$CTL1_IP_NIC1:8774/v2.1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne compute admin http://$CTL1_IP_NIC1:8774/v2.1/%\(tenant_id\)s
}

function nova_install {
          yum -y install openstack-nova-api openstack-nova-conductor \
                              openstack-nova-console openstack-nova-novncproxy \
                              openstack-nova-scheduler
}

function nova_config {
        ctl_nova_conf=/etc/nova/nova.conf
        cp $ctl_nova_conf $ctl_nova_conf.orig

        ops_edit $ctl_nova_conf DEFAULT enabled_apis osapi_compute,metadata
        ops_edit $ctl_nova_conf DEFAULT rpc_backend rabbit
        ops_edit $ctl_nova_conf DEFAULT auth_strategy keystone
        ops_edit $ctl_nova_conf DEFAULT my_ip $CTL1_IP_NIC1
        ops_edit $ctl_nova_conf DEFAULT use_neutron true
        ops_edit $ctl_nova_conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
        ops_edit $ctl_nova_conf DEFAULT osapi_compute_listen \$my_ip
        ops_edit $ctl_nova_conf DEFAULT metadata_listen \$my_ip
        
        ops_edit $ctl_nova_conf DEFAULT instance_usage_audit True
        ops_edit $ctl_nova_conf DEFAULT instance_usage_audit_period hour
        ops_edit $ctl_nova_conf DEFAULT notify_on_state_change vm_and_task_state

        
        ops_edit $ctl_nova_conf api_database connection  mysql+pymysql://nova:$PASS_DATABASE_NOVA_API@$CTL1_IP_NIC1/nova_api
        ops_edit $ctl_nova_conf database connection  mysql+pymysql://nova:$PASS_DATABASE_NOVA@$CTL1_IP_NIC1/nova
        
        ops_edit $ctl_nova_conf oslo_messaging_rabbit rabbit_host $CTL1_IP_NIC1
        ops_edit $ctl_nova_conf oslo_messaging_rabbit rabbit_port 5672
        ops_edit $ctl_nova_conf oslo_messaging_rabbit rabbit_userid openstack
        ops_edit $ctl_nova_conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS

        ops_edit $ctl_nova_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
        ops_edit $ctl_nova_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
        ops_edit $ctl_nova_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
        ops_edit $ctl_nova_conf keystone_authtoken auth_type password
        ops_edit $ctl_nova_conf keystone_authtoken project_domain_name Default
        ops_edit $ctl_nova_conf keystone_authtoken user_domain_name Default
        ops_edit $ctl_nova_conf keystone_authtoken project_name service
        ops_edit $ctl_nova_conf keystone_authtoken username nova
        ops_edit $ctl_nova_conf keystone_authtoken password $NOVA_PASS

        ops_edit $ctl_nova_conf vnc vncserver_listen \$my_ip
        ops_edit $ctl_nova_conf vnc vncserver_proxyclient_address \$my_ip
        ops_edit $ctl_nova_conf vnc novncproxy_host \$my_ip
        
        ops_edit $ctl_nova_conf glance api_servers http://$CTL1_IP_NIC1:9292
        
        ops_edit $ctl_nova_conf oslo_concurrency lock_path /var/lib/nova/tmp
        
        ops_edit $ctl_nova_conf neutron url http://$CTL1_IP_NIC1:9696
        ops_edit $ctl_nova_conf neutron auth_url http://$CTL1_IP_NIC1:35357
        ops_edit $ctl_nova_conf neutron auth_type password
        ops_edit $ctl_nova_conf neutron project_domain_name Default
        ops_edit $ctl_nova_conf neutron user_domain_name Default
        ops_edit $ctl_nova_conf neutron project_name service
        ops_edit $ctl_nova_conf neutron username neutron
        ops_edit $ctl_nova_conf neutron password $NEUTRON_PASS
        ops_edit $ctl_nova_conf neutron service_metadata_proxy True
        ops_edit $ctl_nova_conf neutron metadata_proxy_shared_secret $METADATA_SECRET
        
        ops_edit $ctl_nova_conf oslo_messaging_notifications driver messagingv2
}

function nova_syncdb {
        su -s /bin/sh -c "nova-manage api_db sync" nova
        su -s /bin/sh -c "nova-manage db sync" nova

}

function nova_enable_restart {
            echocolor "Restart dich vu nova"
            systemctl enable openstack-nova-api.service
            systemctl enable openstack-nova-consoleauth.service
            systemctl enable openstack-nova-scheduler.service
            systemctl enable openstack-nova-conductor.service
            systemctl enable openstack-nova-novncproxy.service
            
            systemctl start openstack-nova-api.service
            systemctl start openstack-nova-consoleauth.service
            systemctl start openstack-nova-scheduler.service
            systemctl start openstack-nova-conductor.service
            systemctl start openstack-nova-novncproxy.service
        
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
source config.cfg
source /root/admin-openrc
############################

echocolor "Bat dau cai dat NOVA"
echocolor "Tao DB NOVA"
sleep 3
nova_create_db

echocolor "Tao user va endpoint cho NOVA"
sleep 3
nova_user_endpoint

echocolor "Cai dat NOVA"
sleep 3
nova_install

echocolor "Cau hinh cho NOVA"
sleep 3
nova_config

echocolor "Dong bo DB cho NOVA"
sleep 3
nova_syncdb

echocolor "Restart dich vu NOVA"
sleep 3
nova_enable_restart

echocolor "Da cai dat xong NOVA"
