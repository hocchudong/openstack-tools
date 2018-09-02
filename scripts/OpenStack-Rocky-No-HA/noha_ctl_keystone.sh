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

function create_keystone_db {
				mysql -uroot -p$PASS_DATABASE_ROOT -e "CREATE DATABASE keystone;
				GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$PASS_DATABASE_KEYSTONE';
				GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$PASS_DATABASE_KEYSTONE';
				GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_KEYSTONE';
				FLUSH PRIVILEGES;"
}

function keystone_install_config {
        yum -y install openstack-keystone httpd mod_wsgi
        keystone_conf=/etc/keystone/keystone.conf
        cp $keystone_conf $keystone_conf.orig        
        ops_edit $keystone_conf database connection mysql+pymysql://keystone:$PASS_DATABASE_KEYSTONE@$CTL1_IP_NIC1/keystone
        ops_edit $keystone_conf token provider fernet
}
function keystone_syncdb {
          su -s /bin/sh -c "keystone-manage db_sync" keystone
          keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
          keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
}

function keystone_bootstrap {
          keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
          --bootstrap-admin-url http://$CTL1_IP_NIC1:5000/v3/ \
          --bootstrap-internal-url http://$CTL1_IP_NIC1:5000/v3/ \
          --bootstrap-public-url http://$CTL1_IP_NIC1:5000/v3/ \
          --bootstrap-region-id RegionOne
}

function keystone_config_http() {
          echo "ServerName `hostname`" >> /etc/httpd/conf/httpd.conf
          ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
          systemctl enable httpd.service
          systemctl start httpd.service 
}

function keystone_endpoint() {
        openstack project create service --domain default --description "Service Project" 
        openstack project create demo --domain default --description "Demo Project" 
        openstack user create demo --domain default --password $DEMO_PASS
        openstack role create user
        openstack role add --project demo --user demo user

}

function keystone_create_adminrc {
cat << EOF > /root/admin-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$CTL1_IP_NIC1:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

EOF

sleep 5
echocolor "Execute environment script"
chmod +x /root/admin-openrc
cat  /root/admin-openrc >> /etc/profile
source /root/admin-openrc


cat << EOF > /root/demo-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$CTL1_IP_NIC1:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2

EOF
chmod +x /root/demo-openrc
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
echocolor "Cai dat Keystone"
sleep 3

echocolor "Tao DB keystone"
sleep 3
create_keystone_db

echocolor "Cai dat va cau hinh keystone"
sleep 3
keystone_install_config

echocolor "Sync DB cho keystone"
sleep 3
keystone_syncdb

echocolor "Thu hien bootstrap cho keystone"
sleep 3
keystone_bootstrap

echocolor "Cau hinh http"
sleep 3
keystone_config_http

echocolor "Tao bien moi truong"
sleep 3
keystone_create_adminrc
source /root/admin-openrc

echocolor "Tao Endpoint"
sleep 3
source /root/admin-openrc
keystone_endpoint