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

function cin_cinder_install {
				echocolor "Cai dat cinder-volume tren Cinder nod"
        sleep 3
        yum -y install openstack-cinder targetcli python-keystone


}

function cin_cinder_config {
        cin_cinder_conf=/etc/cinder/cinder.conf
        cp $cin_cinder_conf $cin_cinder_conf.orig

				ops_edit $cin_cinder_conf DEFAULT rpc_backend rabbit
				ops_edit $cin_cinder_conf DEFAULT auth_strategy keystone
				ops_edit $cin_cinder_conf DEFAULT my_ip $CINDER1_IP_NIC1
				ops_edit $cin_cinder_conf DEFAULT control_exchange cinder
				ops_edit $cin_cinder_conf DEFAULT osapi_volume_listen  \$my_ip
				ops_edit $cin_cinder_conf DEFAULT control_exchange cinder
				ops_edit $cin_cinder_conf DEFAULT glance_api_servers http://$CTL1_IP_NIC1:9292
				ops_edit $cin_cinder_conf DEFAULT glance_api_version 2
				ops_edit $cin_cinder_conf DEFAULT enabled_backends lvm
				
				ops_edit $cin_cinder_conf database connection  mysql+pymysql://cinder:$PASS_DATABASE_CINDER@$CTL1_IP_NIC1/cinder

				ops_edit $cin_cinder_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC1:5000
				ops_edit $cin_cinder_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:35357
				ops_edit $cin_cinder_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
				ops_edit $cin_cinder_conf keystone_authtoken auth_type password
				ops_edit $cin_cinder_conf keystone_authtoken project_domain_name Default
				ops_edit $cin_cinder_conf keystone_authtoken user_domain_name Default
				ops_edit $cin_cinder_conf keystone_authtoken project_name service
				ops_edit $cin_cinder_conf keystone_authtoken username cinder
				ops_edit $cin_cinder_conf keystone_authtoken password $CINDER_PASS
				
				ops_edit $cin_cinder_conf oslo_messaging_rabbit rabbit_host $CTL1_IP_NIC1
				ops_edit $cin_cinder_conf oslo_messaging_rabbit rabbit_port 5672
				ops_edit $cin_cinder_conf oslo_messaging_rabbit rabbit_userid openstack
				ops_edit $cin_cinder_conf oslo_messaging_rabbit rabbit_password $RABBIT_PASS
				
				ops_edit $cin_cinder_conf oslo_concurrency lock_path /var/lib/cinder/tmp
				
				ops_edit $cin_cinder_conf oslo_messaging_notifications driver messagingv2
				
				
				ops_edit $cin_cinder_conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
				ops_edit $cin_cinder_conf lvm volume_group cinder-volumes
				ops_edit $cin_cinder_conf lvm iscsi_protocol iscsi
				ops_edit $cin_cinder_conf lvm iscsi_helper lioadm
 
}

function cin_cinder_restart {
				systemctl enable openstack-cinder-volume.service target.service
				systemctl start openstack-cinder-volume.service target.service
}


function create_lvm {
				echocolor "Cai dat LVM"
				sleep 3
				yum -y install lvm2
				systemctl enable lvm2-lvmetad.service
				systemctl start lvm2-lvmetad.service

				pvcreate /dev/sdb
				vgcreate cinder-volumes /dev/sdb

				cp /etc/lvm/lvm.conf /etc/lvm/lvm.conf.orig
				#sed  -r -i 's#(filter = )(\[ "a/\.\*/" \])#\1["a\/sdb\/", "r/\.\*\/"]#g' /etc/lvm/lvm.conf
        
        # fix filter cua lvm tren CentOS 7.4, chen vao dong 141
        sed -i '141i\        filter = [ "a/sdb/", "r/.*/"]' /etc/lvm/lvm.conf
        
}

##############################################################################
# Thuc thi cac functions
## Goi cac functions
##############################################################################
echocolor "Bat dau cai dat CINDER"
sleep 3
create_lvm
cin_cinder_install

echocolor "Cai dat va cau hinh CINDER"
sleep 3
cin_cinder_config

echocolor "Restart dich vu CINDER"
sleep 3
cin_cinder_restart

echocolor "Da cai dat xong CINDER"
