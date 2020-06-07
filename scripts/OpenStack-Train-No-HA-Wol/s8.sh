mysql -uroot -pWelcome789 -e "CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'10.24.44.171' IDENTIFIED BY 'Welcome789';
FLUSH PRIVILEGES;"

source /root/admin-openrc

openstack user create  glance --domain default --password Welcome789

openstack role add --project service --user glance admin

openstack service create --name glance --description "OpenStack Image" image

openstack endpoint create --region RegionOne image public http://10.24.44.171:9292

openstack endpoint create --region RegionOne image internal http://10.24.44.171:9292

openstack endpoint create --region RegionOne image admin http://10.24.44.171:9292

