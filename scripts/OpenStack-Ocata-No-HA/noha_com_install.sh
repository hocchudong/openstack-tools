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

function com_nova_install {
        yum install -y python-openstackclient openstack-selinux openstack-utils
        yum install -y openstack-nova-compute
}

function com_nova_config {
        com_nova_conf=/etc/nova/nova.conf
        cp $com_nova_conf $com_nova_conf.orig

        ops_edit $com_nova_conf DEFAULT enabled_apis osapi_compute,metadata
        ops_edit $com_nova_conf DEFAULT rpc_backend rabbit
        ops_edit $com_nova_conf DEFAULT auth_strategy keystone
        ops_edit $com_nova_conf DEFAULT my_ip $(ip addr show dev ens160 scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
        ops_edit $com_nova_conf DEFAULT use_neutron true
        ops_edit $com_nova_conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
        
        ops_edit $com_nova_conf DEFAULT instance_usage_audit True
        ops_edit $com_nova_conf DEFAULT instance_usage_audit_period hour
        ops_edit $com_nova_conf DEFAULT notify_on_state_change vm_and_task_state

        ops_edit $com_nova_conf oslo_messaging_rabbit rabbit_host $CTL1_IP_NIC1
        ops_edit $com_nova_conf oslo_messaging_rabbit rabbit_port 5672
        ops_edit $com_nova_conf oslo_messaging_rabbit rabbit_userid openstack
        ops_edit $com_nova_conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS

        ops_edit $com_nova_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
        ops_edit $com_nova_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
        ops_edit $com_nova_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
        ops_edit $com_nova_conf keystone_authtoken auth_type password
        ops_edit $com_nova_conf keystone_authtoken project_domain_name Default
        ops_edit $com_nova_conf keystone_authtoken user_domain_name Default
        ops_edit $com_nova_conf keystone_authtoken project_name service
        ops_edit $com_nova_conf keystone_authtoken username nova
        ops_edit $com_nova_conf keystone_authtoken password $NOVA_PASS

        ops_edit $com_nova_conf vnc enabled True
        ops_edit $com_nova_conf vnc vncserver_listen 0.0.0.0
        ops_edit $com_nova_conf vnc vncserver_proxyclient_address \$my_ip
        ops_edit $com_nova_conf vnc novncproxy_base_url http://$CTL1_IP_NIC1:6080/vnc_auto.html
        
        ops_edit $com_nova_conf glance api_servers http://$CTL1_IP_NIC1:9292
        
        ops_edit $com_nova_conf oslo_concurrency lock_path /var/lib/nova/tmp
        
        ops_edit $com_nova_conf neutron url http://$CTL1_IP_NIC1:9696
        ops_edit $com_nova_conf neutron auth_url http://$CTL1_IP_NIC1:35357
        ops_edit $com_nova_conf neutron auth_type password
        ops_edit $com_nova_conf neutron project_domain_name Default
        ops_edit $com_nova_conf neutron user_domain_name Default
        ops_edit $com_nova_conf neutron project_name service
        ops_edit $com_nova_conf neutron username neutron
        ops_edit $com_nova_conf neutron password $NEUTRON_PASS
        
        ops_edit $com_nova_conf libvirt virt_type  $(count=$(egrep -c '(vmx|svm)' /proc/cpuinfo); if [ $count -eq 0 ];then   echo "qemu"; else   echo "kvm"; fi)
        ops_edit $com_nova_conf oslo_messaging_notifications driver messagingv2
 
}

function com_nova_restart {
        systemctl enable libvirtd.service openstack-nova-compute.service
        systemctl start libvirtd.service openstack-nova-compute.service
}

function com_neutron_install {
        yum install -y  openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables
        yum install -y openstack-neutron-linuxbridge ebtables ipset
}

function com_neutron_config {
        com_neutron_conf=/etc/neutron/neutron.conf
        com_ml2_conf=/etc/neutron/plugins/ml2/ml2_conf.ini
        com_linuxbridge_agent=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
        com_dhcp_agent=/etc/neutron/dhcp_agent.ini
        com_metadata_agent=/etc/neutron/metadata_agent.ini
        
        
        cp $com_neutron_conf $com_neutron_conf.orig
        cp $com_ml2_conf $com_ml2_conf.orig
        cp $com_linuxbridge_agent $com_linuxbridge_agent.orig
        cp $com_dhcp_agent $com_dhcp_agent.orig
        cp $com_metadata_agent $com_metadata_agent.orig
        
        ops_edit $com_neutron_conf DEFAULT auth_strategy keystone
        ops_edit $com_neutron_conf DEFAULT core_plugin ml2
        ops_edit $com_neutron_conf DEFAULT rpc_backend rabbit
        ops_edit $com_neutron_conf DEFAULT notify_nova_on_port_status_changes true
        ops_edit $com_neutron_conf DEFAULT notify_nova_on_port_data_changes true
        
        ops_edit $com_neutron_conf oslo_messaging_rabbit rabbit_host $CTL1_IP_NIC1
        ops_edit $com_neutron_conf oslo_messaging_rabbit rabbit_port 5672
        ops_edit $com_neutron_conf oslo_messaging_rabbit rabbit_userid openstack
        ops_edit $com_neutron_conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS
        
        ops_edit $com_neutron_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
        ops_edit $com_neutron_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
        ops_edit $com_neutron_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
        ops_edit $com_neutron_conf keystone_authtoken auth_type password
        ops_edit $com_neutron_conf keystone_authtoken project_domain_name Default
        ops_edit $com_neutron_conf keystone_authtoken user_domain_name Default
        ops_edit $com_neutron_conf keystone_authtoken project_name service
        ops_edit $com_neutron_conf keystone_authtoken username neutron
        ops_edit $com_neutron_conf keystone_authtoken password $NEUTRON_PASS
                
        ops_edit $com_neutron_conf oslo_concurrency lock_path /var/lib/neutron/tmp
        
        ops_edit $com_neutron_conf oslo_messaging_notifications driver messagingv2
        
        ops_edit $com_linuxbridge_agent linux_bridge physical_interface_mappings provider:ens256
        ops_edit $com_linuxbridge_agent vxlan enable_vxlan False
        ops_edit $com_linuxbridge_agent securitygroup enable_security_group True
        ops_edit $com_linuxbridge_agent securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
        
        ops_edit $com_metadata_agent DEFAULT nova_metadata_ip $CTL1_IP_NIC1
        ops_edit $com_metadata_agent DEFAULT metadata_proxy_shared_secret $METADATA_SECRET
        
        ops_edit $com_dhcp_agent DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
        ops_edit $com_dhcp_agent DEFAULT enable_isolated_metadata True
        ops_edit $com_dhcp_agent DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
        ops_edit $com_dhcp_agent DEFAULT force_metadata True
}

function com_neutron_restart {
        systemctl enable neutron-linuxbridge-agent.service
        systemctl enable neutron-metadata-agent.service
        systemctl enable neutron-dhcp-agent.service
        
        systemctl start neutron-linuxbridge-agent.service
        systemctl start neutron-metadata-agent.service
        systemctl start neutron-dhcp-agent.service

}

##############################################################################
# Thuc thi cac functions
## Goi cac functions
##############################################################################
yum -y update 

echocolor "Install dich vu NOVA"
sleep 3
com_nova_install

echocolor "Config dich vu NOVA"
sleep 3
com_nova_config

echocolor "Restart dich vu NOVA"
sleep 3
com_nova_restart

echocolor "Install dich vu NEUTRON"
sleep 3
com_neutron_install

echocolor "Config dich vu NEUTRON"
sleep 3
com_neutron_config

echocolor "Restart dich vu NEUTRON"
sleep 3
com_neutron_restart