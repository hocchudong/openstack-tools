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

function glance_create_db() {
mysql -uroot -p$PASS_DATABASE_ROOT -e "CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$PASS_DATABASE_GLANCE';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$PASS_DATABASE_GLANCE';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_GLANCE';
FLUSH PRIVILEGES;"

}

#Tao endpoint,user cho glance
function glance_user_endpoint() {
        openstack user create  glance --domain default --password $GLANCE_PASS
        openstack role add --project service --user glance admin
        openstack service create --name glance --description "OpenStack Image" image
        openstack endpoint create --region RegionOne image public http://$CTL1_IP_NIC1:9292
        openstack endpoint create --region RegionOne image internal http://$CTL1_IP_NIC1:9292
        openstack endpoint create --region RegionOne image admin http://$CTL1_IP_NIC1:9292
}

#Cau hinh va cai dat glance
function glance_install_config() {

        yum -y install openstack-glance
        glance_api_conf=/etc/glance/glance-api.conf
        glance_registry_conf=/etc/glance/glance-registry.conf
        cp $glance_api_conf $glance_api_conf.orig
        cp $glance_registry_conf $glance_registry_conf.orig

        ###glance_api_conf
				ops_edit $glance_api_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC1

				ops_edit $glance_api_conf glance_store stores file,http
        ops_edit $glance_api_conf glance_store default_store file
        ops_edit $glance_api_conf glance_store filesystem_store_datadir /var/lib/glance/images/

        ops_edit $glance_api_conf database connection mysql+pymysql://glance:$PASS_DATABASE_GLANCE@$CTL1_IP_NIC1/glance

        ops_edit $glance_api_conf keystone_authtoken www_authenticate_uri http://$CTL1_IP_NIC1:5000		
        ops_edit $glance_api_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:5000		
        ops_edit $glance_api_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
        ops_edit $glance_api_conf keystone_authtoken auth_type password
        ops_edit $glance_api_conf keystone_authtoken project_domain_name Default
        ops_edit $glance_api_conf keystone_authtoken user_domain_name Default
        ops_edit $glance_api_conf keystone_authtoken project_name service
        ops_edit $glance_api_conf keystone_authtoken username glance
        ops_edit $glance_api_conf keystone_authtoken password $GLANCE_PASS
        
        ops_edit $glance_api_conf paste_deploy flavor keystone
        ops_edit $glance_api_conf oslo_messaging_notifications driver messagingv2

        ###glance_registry_conf
				ops_edit $glance_registry_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC1
        ops_edit $glance_registry_conf database connection mysql+pymysql://glance:$PASS_DATABASE_GLANCE@$CTL1_IP_NIC1/glance

        ops_edit $glance_registry_conf keystone_authtoken www_authenticate_uri http://$CTL1_IP_NIC1:5000		
        ops_edit $glance_registry_conf keystone_authtoken auth_url http://$CTL1_IP_NIC1:5000		
        ops_edit $glance_registry_conf keystone_authtoken memcached_servers $CTL1_IP_NIC1:11211
        ops_edit $glance_registry_conf keystone_authtoken auth_type password
        ops_edit $glance_registry_conf keystone_authtoken project_domain_name Default
        ops_edit $glance_registry_conf keystone_authtoken user_domain_name Default
        ops_edit $glance_registry_conf keystone_authtoken project_name service
        ops_edit $glance_registry_conf keystone_authtoken username glance
        ops_edit $glance_registry_conf keystone_authtoken password $GLANCE_PASS
        
        ops_edit $glance_registry_conf paste_deploy flavor keystone
        
        ops_edit $glance_registry_conf oslo_messaging_notifications driver messagingv2
        
}

#Dong bo DB cho lance
function glance_syncdb() {
        su -s /bin/sh -c "glance-manage db_sync" glance
}


function glance_enable_restart() {
        systemctl enable openstack-glance-api.service
        systemctl enable openstack-glance-registry.service
        systemctl start openstack-glance-api.service
        systemctl start openstack-glance-registry.service
}

function glance_create_image() {
        wget http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
        openstack image create "cirros" --file cirros-0.3.5-x86_64-disk.img \
        --disk-format qcow2 --container-format bare \
        --public
        
        openstack image list       
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
source config.cfg
source /root/admin-openrc
############################

echocolor "Bat dau cai dat Glance"
echocolor "Tao DB Glance"
sleep 3
glance_create_db

echocolor "Tao user va endpoint cho Glance"
sleep 3
glance_user_endpoint

echocolor "Cai dat va cau hinh Glance"
sleep 3
glance_install_config

echocolor "Dong bo DB cho Glance"
sleep 3
glance_syncdb

echocolor "Restart dich vu glance"
sleep 3
glance_enable_restart

echocolor "Tao images"
sleep 3
glance_create_image

echocolor "Da cai dat xong Glance"
