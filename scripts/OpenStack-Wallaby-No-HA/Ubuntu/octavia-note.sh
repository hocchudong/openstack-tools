openstack user create --domain default --project service --password servicepassword octavia

openstack role add --project service --user octavia admin

openstack service create --name octavia --description "OpenStack LBaaS" load-balancer

export octavia_api=10.0.0.50

openstack endpoint create --region RegionOne load-balancer public http://$octavia_api:9876
openstack endpoint create --region RegionOne load-balancer internal http://$octavia_api:9876
openstack endpoint create --region RegionOne load-balancer admin http://$octavia_api:9876

########
mysql

create database octavia; 

grant all privileges on octavia.* to octavia@'localhost' identified by 'password'; 

grant all privileges on octavia.* to octavia@'%' identified by 'password'; 

flush privileges; 

exit
########

apt -y install octavia-api octavia-health-manager octavia-housekeeping octavia-worker


 mkdir -p /etc/octavia/certs/private
 
 mkdir ~/work
 
 cd ~/work
 
 git clone https://opendev.org/openstack/octavia.git
 
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


