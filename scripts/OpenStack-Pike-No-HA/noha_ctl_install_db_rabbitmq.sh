#!/bin/bash -ex
### Script cai dat rabbitmq tren mq1

source config.cfg 

function echocolor {
    echo "#######################################################################"
    echo "$(tput setaf 3)##### $1 #####$(tput sgr0)"
    echo "#######################################################################"

}

function ops_edit {
    crudini --set $1 $2 $3 $4
}

# Cach dung
## Cu phap:
##			ops_edit_file $bien_duong_dan_file [SECTION] [PARAMETER] [VALUAE]
## Vi du:
###			filekeystone=/etc/keystone/keystone.conf
###			ops_edit_file $filekeystone DEFAULT rpc_backend rabbit


# Ham de del mot dong trong file cau hinh
function ops_del {
    crudini --del $1 $2 $3
}

function install_mariadb_galera {
        echocolor "Cai dat DB"
        yum -y install mariadb mariadb-server python2-PyMySQL rsync xinetd crudini vim
        
cat << EOF > /etc/my.cnf.d/openstack.cnf
[mysqld]
bind-address = 0.0.0.0

default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF
        
}

function set_pass_db {
          echocolor "Dat pass cho DB"
          sleep 3
cat << EOF | mysql -uroot
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$PASS_DATABASE_ROOT' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$PASS_DATABASE_ROOT' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY '$PASS_DATABASE_ROOT' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'$CTL1_IP_NIC1' IDENTIFIED BY '$PASS_DATABASE_ROOT' WITH GRANT OPTION ;FLUSH PRIVILEGES;
DROP USER ''@'$CTL1_HOSTNAME';
DROP USER ''@'localhost';
DROP USER 'root'@'::1';
DROP USER 'root'@'$CTL1_HOSTNAME';
EOF
}

function restart_db {
        echocolor "Khoi dong lai DB"
        sleep 3
        systemctl enable mariadb.service
        systemctl start mariadb.service
}

function rabbitmq_install {
        echocolor "Cai dat rabbitmq"
        sleep 3
        yum -y install rabbitmq-server

        systemctl enable rabbitmq-server.service
        systemctl start rabbitmq-server.service
        rabbitmq-plugins enable rabbitmq_management
        systemctl restart rabbitmq-server
        curl -O http://localhost:15672/cli/rabbitmqadmin
        chmod a+x rabbitmqadmin
        mv rabbitmqadmin /usr/sbin/
        
}

function rabbitmq_create_user() {
	rabbitmqctl add_user openstack $RABBIT_PASS
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
	rabbitmqctl set_user_tags openstack administrator
	rabbitmqadmin list users
}

### Thuc hien ham
install_mariadb_galera
restart_db
set_pass_db
restart_db

echocolor "Tao user cho rabbitmq"
rabbitmq_install
rabbitmq_create_user