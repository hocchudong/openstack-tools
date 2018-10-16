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
        ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""
        for IP_ADD in $CTL1_IP_NIC1 $COM1_IP_NIC1 $COM2_IP_NIC1
        do
                ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub root@$IP_ADD
        done
}

function setup_config {
        for IP_ADD in $CTL1_IP_NIC1 $COM1_IP_NIC1 $COM2_IP_NIC1
        do
                scp ./config.cfg root@$IP_ADD:/root/
                chmod +x config.cfg

        done
}

function install_proxy {
        
        for IP_ADD in $CTL1_IP_NIC1 $COM1_IP_NIC1 $COM2_IP_NIC1
        do
            echocolor "Cai dat install_proxy tren $IP_ADD"
            sleep 3
            ssh root@$IP_ADD 'echo "proxy=http://192.168.20.12:3142" >> /etc/yum.conf' 
            yum -y update

        done

}
function install_repo_galera {
        for IP_ADD in $CTL1_IP_NIC1 $COM1_IP_NIC1 $COM2_IP_NIC1
        do
            echocolor "Cai dat install_repo_galera tren $IP_ADD"
            sleep 3
ssh root@$IP_ADD << EOF
echo '[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo
yum -y update
EOF
        done


}

function install_repo_openstack {
        for IP_ADD in $CTL1_IP_NIC1 $COM1_IP_NIC1 $COM2_IP_NIC1
        do
            echocolor "Cai dat install_repo tren $IP_ADD"
            sleep 3
        ssh root@$IP_ADD << EOF 
yum -y install centos-release-openstack-rocky
yum -y upgrade
yum -y install crudini wget vim
yum -y install python-openstackclient openstack-selinux python2-PyMySQL
yum -y update
EOF
        done
}

function khai_bao_host {
        echo "$CTL1_IP_NIC1 controller1" >> /etc/hosts
        echo "$COM1_IP_NIC1 compute1" >> /etc/hosts
        echo "$COM2_IP_NIC1 compute2" >> /etc/hosts
        echo "$CINDER1_IP_NIC1 cinder1" >> /etc/hosts
        echo "$SWIFT1_IP_NIC1 swift1" >> /etc/hosts
        echo "$SWIFT2_IP_NIC1 swift2" >> /etc/hosts
        scp /etc/hosts root@$COM1_IP_NIC1:/etc/
        scp /etc/hosts root@$COM2_IP_NIC1:/etc/
}

# Cai dat NTP server 
function install_ntp_server {
        yum -y install chrony
        for IP_ADD in $CTL1_IP_NIC1 $COM1_IP_NIC1 $COM2_IP_NIC1
        do 
          echocolor "Cau hinh NTP cho $IP_ADD"
          sleep 3
          cp /etc/chrony.conf /etc/chrony.conf.orig
          if [ "$IP_ADD" == "$CTL1_IP_NIC1" ]; then
                  sed -i 's/server 0.centos.pool.ntp.org iburst/ \
server 1.vn.pool.ntp.org iburst \
server 0.asia.pool.ntp.org iburst \
server 3.asia.pool.ntp.org iburst/g' /etc/chrony.conf
                  sed -i 's/server 1.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
                  sed -i 's/server 2.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
                  sed -i 's/server 3.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
                  sed -i 's/#allow 192.168\/16/allow 192.168.20.0\/24/g' /etc/chrony.conf
                  sleep 5                  
                  systemctl enable chronyd.service
                  systemctl start chronyd.service
                  systemctl restart chronyd.service
                  chronyc sources
          else 
                  ssh root@$IP_ADD << EOF               
sed -i 's/server 0.centos.pool.ntp.org iburst/server $CTL1_IP_NIC1 iburst/g' /etc/chrony.conf
sed -i 's/server 1.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
sed -i 's/server 2.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
sed -i 's/server 3.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
systemctl enable chronyd.service
systemctl start chronyd.service
systemctl restart chronyd.service
chronyc sources
EOF
          fi  
        done        
}

function install_memcached() {
        yum -y install memcached python-memcached
        cp /etc/sysconfig/memcached /etc/sysconfig/memcached.orig
        #IP_LOCAL=`ip -o -4 addr show dev eth1 | sed 's/.* inet \([^/]*\).*/\1/'`
        sed -i "s/-l 127.0.0.1,::1/-l 127.0.0.1,::1,$CTL1_IP_NIC1/g" /etc/sysconfig/memcached
				systemctl enable memcached.service
				systemctl start memcached.service
}

##############################################################################
# Thuc thi cac functions
## Goi cac functions
##############################################################################
echocolor "Cai dat cac goi chuan bi tren CONTROLLER"
sleep 3

echocolor "Tao key va copy key, bien khai bao sang cac node"
sleep 3
copykey
setup_config

echocolor "Cai dat proxy tren cac node"
sleep 3
#install_proxy

echocolor "Cai dat repo tren cac node"
sleep 3
install_repo_galera
install_repo_openstack

echocolor "Cau hinh hostname"
sleep 3
khai_bao_host

# Cai dat NTP 
echocolor "Cai dat Memcached tren cac node"
install_ntp_server
install_memcached
###

echocolor "Dat hostname cho cac may"
sleep 3
hostnamectl set-hostname $CTL1_HOSTNAME
ssh root@$COM1_IP_NIC1 "hostnamectl set-hostname $COM1_HOSTNAME"
ssh root@$COM2_IP_NIC1 "hostnamectl set-hostname $COM2_HOSTNAME"

echocolor "XONG & KHOI DONG LAI MAY CHU"
sleep 5
ssh root@$COM1_IP_NIC1 'init 6'
ssh root@$COM2_IP_NIC1 'init 6'
init 6