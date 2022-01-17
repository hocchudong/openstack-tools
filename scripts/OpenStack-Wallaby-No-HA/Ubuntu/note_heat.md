# Ghi chep cai dat heat

## Tao DB

mysql -uroot -p$PASS_DATABASE_ROOT
CREATE DATABASE heat; 
GRANT ALL PRIVILEGES ON heat.* TO heat@'localhost' IDENTIFIED BY '$PASS_DATABASE_HEAT'; 
GRANT ALL PRIVILEGES ON heat.* TO heat@'%' IDENTIFIED BY '$PASS_DATABASE_HEAT'; 
FLUSH PRIVILEGES;
EOF


## Tao endpoint

openstack user create heat --domain default --project service --password $HEAT_PASS
openstack role add --project service --user heat admin

openstack service create --name heat --description "Openstack Orchestration" orchestration
openstack service create --name heat-cfn --description "Openstack Orchestration" cloudformation

openstack endpoint create --region RegionOne orchestration public http://CTL1_IP_NIC2:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne orchestration internal http://$CTL1_IP_NIC2:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne orchestration admin http://$CTL1_IP_NIC2:8004/v1/%\(tenant_id\)s
 
openstack endpoint create --region RegionOne cloudformation public http://$CTL1_IP_NIC2:8000/v1
openstack endpoint create --region RegionOne cloudformation internal http://$CTL1_IP_NIC2:8000/v1
openstack endpoint create --region RegionOne cloudformation admin http://$CTL1_IP_NIC2:8000/v1

openstack domain create --description "Stack projects and users" heat
openstack user create heat_domain_admin --domain heat --password $HEAT_PASS

openstack role add --domain heat --user heat_domain_admin admin

openstack role create heat_stack_owner
openstack role add --project admin --user admin heat_stack_owner

openstack role create heat_stack_user
