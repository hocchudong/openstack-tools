mysql -uroot -pWelcome789 -e "CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'10.24.44.171' IDENTIFIED BY 'Welcome789';
FLUSH PRIVILEGES;"

openstack user create  placement --domain default --password Welcome789

openstack role add --project service --user placement admin

openstack service create --name placement --description "Placement API" placement

openstack endpoint create --region RegionOne placement public http://10.24.44.171:8778

openstack endpoint create --region RegionOne placement internal http://10.24.44.171:8778

openstack endpoint create --region RegionOne placement admin http://10.24.44.171:8778

yum install -y openstack-placement-api

cp /etc/placement/placement.conf /etc/placement/placement.conf.orig


crudini --set  /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:Welcome789@10.24.44.171/placement
crudini --set  /etc/placement/placement.conf api auth_strategy keystone
crudini --set  /etc/placement/placement.conf keystone_authtoken auth_url  http://10.24.44.171:5000/v3
crudini --set  /etc/placement/placement.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set  /etc/placement/placement.conf keystone_authtoken auth_type password
crudini --set  /etc/placement/placement.conf keystone_authtoken project_domain_name Default
crudini --set  /etc/placement/placement.conf keystone_authtoken user_domain_name Default
crudini --set  /etc/placement/placement.conf keystone_authtoken project_name service
crudini --set  /etc/placement/placement.conf keystone_authtoken username placement
crudini --set  /etc/placement/placement.conf keystone_authtoken password Welcome789

cat <<EOF>> /etc/httpd/conf.d/00-nova-placement-api.conf
<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>
EOF

su -s /bin/sh -c "placement-manage db sync" placement


systemctl restart httpd


