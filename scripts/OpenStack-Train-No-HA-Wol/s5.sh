yum install rabbitmq-server -y

systemctl enable rabbitmq-server.service

systemctl start rabbitmq-server.service

rabbitmq-plugins enable rabbitmq_management

systemctl restart rabbitmq-server

curl -O http://localhost:15672/cli/rabbitmqadmin

chmod a+x rabbitmqadmin

mv rabbitmqadmin /usr/sbin/

rabbitmqctl add_user openstack Welcome789

rabbitmqctl set_permissions openstack ".*" ".*" ".*"

rabbitmqctl set_user_tags openstack administrator

rabbitmqctl list_users
