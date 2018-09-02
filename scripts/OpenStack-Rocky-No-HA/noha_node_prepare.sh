#!/bin/bash -ex 
##############################################################################
### Script cai dat cac goi bo tro cho CTL

### Khai bao bien de thuc hien

chmod +x config.cfg
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

function copykey {
         ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$1
}

function setup_config {
				scp /root/OpenStack-Pike-No-HA/config.cfg root@$1:/root/
				chmod +x config.cfg
}

function install_proxy {
				echocolor "Cai dat install_proxy tren $1"
				sleep 3
				ssh root@$1 'echo "proxy=http://192.168.20.12:3142" >> /etc/yum.conf' 
				yum -y update

}
function install_repo_galera {
            echocolor "Cai dat install_repo_galera tren $1"
            sleep 3
ssh root@$1 << EOF
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo
yum -y update
EOF
}

function install_repo {
            echocolor "Cai dat install_repo tren $1"
            sleep 3
ssh root@$1 << EOF 
yum -y install centos-release-openstack-pike
yum -y upgrade
yum -y install crudini wget vim
yum -y install python-openstackclient openstack-selinux python2-PyMySQL
yum -y update
EOF
}

function khai_bao_host {
        scp /etc/hosts root@$1:/etc/

}

# Cai dat NTP server 
function install_ntp_server {
        
				echocolor "Cau hinh NTP cho $1"
        sleep 3 
ssh root@$1 << EOF
yum -y install chrony									
sed -i 's/server 0.centos.pool.ntp.org iburst/server $CTL1_IP_NIC1 iburst/g' /etc/chrony.conf
sed -i 's/server 1.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
sed -i 's/server 2.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
sed -i 's/server 3.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
systemctl enable chronyd.service
systemctl start chronyd.service
systemctl restart chronyd.service
chronyc sources
EOF
      
}

##############################################################################
# Thuc thi cac functions
## Goi cac functions
##############################################################################
echocolor "Cau hinh cac goi chuan bi cho client"
sleep 3

echocolor "Tao key va copy key, bien khai bao sang cac node"
sleep 3
copykey $1
setup_config $1

echocolor "Cai dat proxy tren cac node"
sleep 3
install_proxy $1

echocolor "Cai dat repo tren cac node"
sleep 3
install_repo_galera $1
install_repo $1

echocolor "Cau hinh hostname"
sleep 3
khai_bao_host $1

# Cai dat NTP 
echocolor "Cai dat Memcached tren cac node"
install_ntp_server $1
###
echocolor "XONG & KHOI DONG LAI MAY CHU"
sleep 5

ssh root@$1 'init 6'

