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

function neutron_create_db {
      mysql -uroot -p$PASS_DATABASE_ROOT -e "CREATE DATABASE neutron;
      GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$PASS_DATABASE_NEUTRON';
      GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$PASS_DATABASE_NEUTRON';
      GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_NEUTRON';

      FLUSH PRIVILEGES;"
}

function neutron_user_endpoint {
        openstack user create  neutron --domain default --password $NEUTRON_PASS
        openstack role add --project service --user neutron admin
        openstack service create --name neutron --description "OpenStack Networking" network
        openstack endpoint create --region RegionOne network public http://$CTL1_IP_NIC1:9696
        openstack endpoint create --region RegionOne network internal  http://$CTL1_IP_NIC1:9696
        openstack endpoint create --region RegionOne network admin  http://$CTL1_IP_NIC1:9696

}

function neutron_install {
        yum -y update && yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables


}

function neutron_config {		
				ctl_neutron_conf=/etc/neutron/neutron.conf
        ctl_ml2_conf=/etc/neutron/plugins/ml2/ml2_conf.ini
        ctl_linuxbridge_agent=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
        ctl_dhcp_agent=/etc/neutron/dhcp_agent.ini
        ctl_metadata_agent=/etc/neutron/metadata_agent.ini
				ctl_l3_agent_conf=/etc/neutron/l3_agent.ini
        
        
        cp $ctl_neutron_conf $com_neutron_conf.orig
        cp $ctl_ml2_conf $com_ml2_conf.orig
        cp $ctl_linuxbridge_agent $com_linuxbridge_agent.orig
        cp $ctl_dhcp_agent $com_dhcp_agent.orig
        cp $ctl_metadata_agent $com_metadata_agent.orig

        ops_edit $ctl_neutron_conf DEFAULT core_plugin ml2
        ops_edit $ctl_neutron_conf DEFAULT service_plugins router
        ops_edit $ctl_neutron_conf DEFAULT auth_strategy keystone    
				ops_edit $ctl_neutron_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC1
        ops_edit $ctl_neutron_conf DEFAULT notify_nova_on_port_status_changes True
        ops_edit $ctl_neutron_conf DEFAULT notify_nova_on_port_data_changes True  
        ops_edit $ctl_neutron_conf DEFAULT allow_overlapping_ips True 
        ops_edit $ctl_neutron_conf DEFAULT dhcp_agents_per_network 2
                
        ops_edit $ctl_neutron_conf database connection  mysql+pymysql://neutron:$PASS_DATABASE_NEUTRON@$CTL1_IP_NIC1/neutron
        
        ops_edit $ctl_neutron_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
        ops_edit $ctl_neutron_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
        ops_edit $ctl_neutron_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
        ops_edit $ctl_neutron_conf keystone_authtoken auth_type password
        ops_edit $ctl_neutron_conf keystone_authtoken project_domain_name Default
        ops_edit $ctl_neutron_conf keystone_authtoken user_domain_name Default
        ops_edit $ctl_neutron_conf keystone_authtoken project_name service
        ops_edit $ctl_neutron_conf keystone_authtoken username neutron
        ops_edit $ctl_neutron_conf keystone_authtoken password $NEUTRON_PASS
        			                
        ops_edit $ctl_neutron_conf oslo_concurrency lock_path /var/lib/neutron/tmp
        
        ops_edit $ctl_neutron_conf oslo_messaging_notifications driver messagingv2
        
        ops_edit $ctl_neutron_conf linux_bridge physical_interface_mappings provider:ens256
        ops_edit $ctl_neutron_conf vxlan enable_vxlan False
        ops_edit $ctl_neutron_conf securitygroup enable_security_group True
        ops_edit $ctl_neutron_conf securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
				      
        ops_edit $ctl_neutron_conf DEFAULT nova_metadata_ip $CTL1_IP_NIC1
        ops_edit $ctl_neutron_conf DEFAULT metadata_proxy_shared_secret $METADATA_SECRET
                
        ops_edit $ctl_neutron_conf nova auth_url http://$CTL1_IP_NIC1:35357
        ops_edit $ctl_neutron_conf nova auth_type password
        ops_edit $ctl_neutron_conf nova project_domain_name Default
        ops_edit $ctl_neutron_conf nova user_domain_name Default
        ops_edit $ctl_neutron_conf nova region_name RegionOne
        ops_edit $ctl_neutron_conf nova project_name service
        ops_edit $ctl_neutron_conf nova username nova
        ops_edit $ctl_neutron_conf nova password $NOVA_PASS
        
        ops_edit $ctl_neutron_conf oslo_concurrency lock_path /var/lib/neutron/tmp
        
        ops_edit $ctl_ml2_conf ml2 type_drivers flat,vlan
        ops_edit $ctl_ml2_conf ml2 tenant_network_types 
        ops_edit $ctl_ml2_conf ml2 mechanism_drivers linuxbridge
        ops_edit $ctl_ml2_conf ml2 extension_drivers port_security          
        ops_edit $ctl_ml2_conf ml2_type_flat flat_networks provider
        
        ops_edit $ctl_ml2_conf securitygroup enable_ipset True
				
        ops_edit $ctl_l3_agent_conf interface_driver linuxbridge
       
        ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
}

function neutron_syncdb {
        echocolor "Dong bo db cho neutron"
        sleep 3
        su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
            --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

}

function neutron_enable_restart {
            echocolor "Khoi dong dich vu NEUTRON"
            sleep 3
            systemctl enable neutron-server.service
            systemctl start neutron-server.service
						#systemctl enable neutron-linuxbridge-agent.service
						#systemctl start neutron-linuxbridge-agent.service
						#systemctl enable neutron-metadata-agent.service
						#systemctl start neutron-metadata-agent.service
						systemctl enable neutron-l3-agent.service
						systemctl start neutron-l3-agent.service
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
source config.cfg
source /root/admin-openrc
############################

echocolor "Bat dau cai dat NEUTRON"
echocolor "Tao DB NEUTRON"
sleep 3
neutron_create_db

echocolor "Tao user va endpoint cho NEUTRON"
sleep 3
neutron_user_endpoint

echocolor "Cai dat NEUTRON"
sleep 3
neutron_install

echocolor "Cau hinh cho NEUTRON"
sleep 3
neutron_config

#Dong bo DB cho NEUTRON"
neutron_syncdb

echocolor "Restart dich vu NEUTRON"
sleep 3
neutron_enable_restart

echocolor "Da cai dat xong NEUTRON"
