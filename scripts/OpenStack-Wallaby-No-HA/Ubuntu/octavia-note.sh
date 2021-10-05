openstack user create --domain default --project service --password Welcome123 octavia

openstack role add --project service --user octavia admin

openstack service create --name octavia --description "OpenStack LBaaS" load-balancer

CTL1_IP_NIC2=172.16.70.90

openstack endpoint create --region RegionOne load-balancer public http://$CTL1_IP_NIC2:9876
openstack endpoint create --region RegionOne load-balancer internal http://$CTL1_IP_NIC2:9876
openstack endpoint create --region RegionOne load-balancer admin http://$CTL1_IP_NIC2:9876

########
mysql -u root -pWelcome123

create database octavia; 

grant all privileges on octavia.* to octavia@'localhost' identified by 'Welcome123'; 

grant all privileges on octavia.* to octavia@'%' identified by 'Welcome123'; 

FLUSH PRIVILEGES;
exit
########

apt -y install octavia-api octavia-health-manager octavia-housekeeping octavia-worker

mkdir -p /etc/octavia/certs/private

mkdir ~/work

cd ~/work

git clone https://opendev.org/openstack/octavia.git -b stable/wallaby

cd octavia/bin
 
./create_dual_intermediate_CA.sh

cp -p ./dual_ca/etc/octavia/certs/server_ca.cert.pem /etc/octavia/certs
cp -p ./dual_ca/etc/octavia/certs/server_ca-chain.cert.pem /etc/octavia/certs
cp -p ./dual_ca/etc/octavia/certs/server_ca.key.pem /etc/octavia/certs/private
cp -p ./dual_ca/etc/octavia/certs/client_ca.cert.pem /etc/octavia/certs
cp -p ./dual_ca/etc/octavia/certs/client.cert-and-key.pem /etc/octavia/certs/private

chown -R octavia /etc/octavia/certs


######

mv /etc/octavia/octavia.conf /etc/octavia/octavia.conf.org


[DEFAULT]
transport_url = rabbit://openstack:Welcome123@172.16.70.90

[api_settings]
bind_host = 172.16.70.90
bind_port = 9876
auth_strategy = keystone
api_base_uri = http://172.16.70.90:9876

[database]

connection = mysql+pymysql://octavia:Welcome123@172.16.70.90/octavia


[health_manager]
bind_ip = 0.0.0.0
bind_port = 5555


[keystone_authtoken]
www_authenticate_uri = http://172.16.70.90:5000
auth_url = http://172.16.70.90:5000
memcached_servers = 172.16.70.90:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = octavia
password = Welcome123

[certificates]

ca_private_key = /etc/octavia/certs/private/server_ca.key.pem
ca_certificate = /etc/octavia/certs/server_ca.cert.pem
server_certs_key_passphrase = insecure-key-do-not-use-this-key
ca_private_key_passphrase = not-secure-passphrase

[haproxy_amphora]
server_ca = /etc/octavia/certs/server_ca-chain.cert.pem
client_cert = /etc/octavia/certs/private/client.cert-and-key.pem


[controller_worker]
client_ca = /etc/octavia/certs/client_ca.cert.pem


[oslo_messaging]
topic = octavia_prov


[service_auth]
auth_url = http://172.16.70.90:5000
memcached_servers = 172.16.70.90:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = octavia
password = Welcome123

