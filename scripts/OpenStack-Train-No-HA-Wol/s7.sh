mysql -uroot -pWelcome789 -e "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'10.24.44.171' IDENTIFIED BY 'Welcome789';
FLUSH PRIVILEGES;"

yum install openstack-keystone httpd mod_wsgi -y


cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig


crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:Welcome789@10.24.44.171/keystone

crudini --set /etc/keystone/keystone.conf token provider fernet

chown root:keystone /etc/keystone/keystone.conf

su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password Welcome789 \
--bootstrap-admin-url http://10.24.44.171:5000/v3/ \
--bootstrap-internal-url http://10.24.44.171:5000/v3/ \
--bootstrap-public-url http://10.24.44.171:5000/v3/ \
--bootstrap-region-id RegionOne

echo "ServerName `hostname`" >> /etc/httpd/conf/httpd.conf

ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/

systemctl enable httpd.service

systemctl start httpd.service

systemctl status httpd.service


cat << EOF > /root/admin-openrc
export OS_USERNAME=admin
export OS_PASSWORD=Welcome789
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://10.24.44.171:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

chmod +x /root/admin-openrc

cat  /root/admin-openrc >> /etc/profile

source /root/admin-openrc

openstack token issue

openstack project create service --domain default --description "Service Project" 
openstack project create demo --domain default --description "Demo Project" 
openstack user create demo --domain default --password Welcome789
openstack role create user
openstack role add --project demo --user demo user



