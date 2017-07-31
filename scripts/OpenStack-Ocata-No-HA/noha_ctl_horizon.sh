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


echocolor "Installing Dashboard package"
yum -y install openstack-dashboard


echocolor "Creating redirect page"

filehtml=/var/www/html/index.html
touch $filehtml
cat << EOF >> $filehtml
<html>
<head>
<META HTTP-EQUIV="Refresh" Content="0.5; URL=http://$CTL1_IP_NIC1/dashboard">
</head>
<body>
<center> <h1>Redirecting to OpenStack Dashboard</h1> </center>
</body>
</html>
EOF


echocolor "Config dashboard"
sleep 3
cp /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.orig
    
filehorizon=/etc/openstack-dashboard/local_settings

sed -i -e "s/'can_set_password': False/'can_set_password': True/g" $filehorizon
sed -i -e "s#ALLOWED_HOSTS.*#ALLOWED_HOSTS = ['*',]#g"  $filehorizon
sed -i -e "s/_member_/user/g" $filehorizon
sed -i -e "s/127.0.0.1/$CTL1_IP_NIC1/g" $filehorizon
sed -i -e "s/http:\/\/\%s:5000\/v2.0/http:\/\/\%s:5000\/v3/g" $filehorizon
sed -i -e "s#^CACHES#SESSION_ENGINE = 'django.contrib.sessions.backends.cache'\nCACHES#g#" $filehorizon
sed -i -e "s#locmem.LocMemCache'#memcached.MemcachedCache',\n        'LOCATION' : [ '192.168.20.33:11211', ]#g" $filehorizon
sed -i -e 's/^#OPENSTACK_API_VERSIONS.*/OPENSTACK_API_VERSIONS = {\n    "identity": 3,\n    "image": 2,\n    "volume": 2,\n}\n#OPENSTACK_API_VERSIONS = {/g'  $filehorizon
sed -i -e "s/^#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN.*/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'default'/g"   $filehorizon

## /* Restarting apache2 and memcached
 systemctl restart httpd.service memcached.service
echocolor "Finish setting up Horizon"

echocolor "INFORMATION "
##################################################################
echo "LOGIN INFORMATION IN HORIZON"
echo "URL: http://$CTL1_IP_NIC1/dashboard"
echo "User: admin or demo"
echo "Password: $ADMIN_PASS"
##################################################################
echocolor "I-M-OK- :)"