#!/bin/bash
#Author HOC CHU DONG
DATE_EXEC="$(date "+%d/%m/%Y %H:%M")"
TIME_START=`date +%s.%N`

source function.sh
source config.cfg

# Function create database for Cinder
function cinder_create_db () {
  echocolor "Create database for Cinder"
  sleep 3

cat << EOF | mysql -uroot -p$PASS_DATABASE_ROOT
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '$PASS_DATABASE_CINDER';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$PASS_DATABASE_CINDER';
FLUSH PRIVILEGES;
EOF
}

function cinder_user_endpoint() {
  openstack user create  cinder --domain default --password $CINDER_PASS
  openstack role add --project service --user cinder admin

  openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
  openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

  openstack endpoint create --region RegionOne volumev2 public http://$CTL1_IP_NIC2:8776/v2/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volumev2 internal http://$CTL1_IP_NIC2:8776/v2/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volumev2 admin http://$CTL1_IP_NIC2:8776/v2/%\(tenant_id\)s

  openstack endpoint create --region RegionOne volumev3 public http://$CTL1_IP_NIC2:8776/v3/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volumev3 internal http://$CTL1_IP_NIC2:8776/v3/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volumev3 admin http://$CTL1_IP_NIC2:8776/v3/%\(tenant_id\)s


}

function cinder_install_config() {
  echocolor "Cai dat cinder"
  sleep 3
  apt install -y cinder-api cinder-scheduler
  apt install -y lvm2  tgt thin-provisioning-tools
  apt install -y cinder-volume python3-mysqldb python3-rtslib-fb
  ctl_cinder_conf=/etc/cinder/cinder.conf
  
  cp $ctl_cinder_conf $ctl_cinder_conf.orig

  if [ "$CINDER_AIO" == "yes" ]; then
    ops_add $ctl_cinder_conf DEFAULT auth_strategy keystone
    ops_add $ctl_cinder_conf DEFAULT my_ip $CTL1_IP_NIC2
    ops_add $ctl_cinder_conf DEFAULT control_exchange cinder
    ops_add $ctl_cinder_conf DEFAULT osapi_volume_listen  \$my_ip
    ops_add $ctl_cinder_conf DEFAULT control_exchange cinder
    ops_add $ctl_cinder_conf DEFAULT glance_api_servers http://$CTL1_IP_NIC2:9292
    ops_add $ctl_cinder_conf DEFAULT enabled_backends lvm
    ops_add $ctl_cinder_conf DEFAULT enable_v3_api True
    ops_add $ctl_cinder_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC2

    ops_add $ctl_cinder_conf database connection  mysql+pymysql://cinder:$PASS_DATABASE_CINDER@$CTL1_IP_NIC2/cinder

    ops_add $ctl_cinder_conf keystone_authtoken www_authenticate_uri http://$CTL1_IP_NIC2:5000
    ops_add $ctl_cinder_conf keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000
    ops_add $ctl_cinder_conf keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211
    ops_add $ctl_cinder_conf keystone_authtoken auth_type password
    ops_add $ctl_cinder_conf keystone_authtoken project_domain_name Default
    ops_add $ctl_cinder_conf keystone_authtoken user_domain_name Default
    ops_add $ctl_cinder_conf keystone_authtoken project_name service
    ops_add $ctl_cinder_conf keystone_authtoken username cinder
    ops_add $ctl_cinder_conf keystone_authtoken password $CINDER_PASS

    ops_add $ctl_cinder_conf oslo_concurrency lock_path /var/lib/cinder/tmp

    ops_add $ctl_cinder_conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
    ops_add $ctl_cinder_conf lvm volume_group cinder-volumes
    ops_add $ctl_cinder_conf lvm iscsi_protocol iscsi
    ops_add $ctl_cinder_conf lvm iscsi_helper tgtadm
  else
    ops_add $ctl_cinder_conf DEFAULT auth_strategy keystone
    ops_add $ctl_cinder_conf DEFAULT my_ip $CTL1_IP_NIC2
    ops_add $ctl_cinder_conf DEFAULT control_exchange cinder
    ops_add $ctl_cinder_conf DEFAULT osapi_volume_listen \$my_ip
    ops_add $ctl_cinder_conf DEFAULT control_exchange cinder
    ops_add $ctl_cinder_conf DEFAULT glance_api_servers http://$CTL1_IP_NIC2:9292


    ops_add $ctl_cinder_conf database connection  mysql+pymysql://cinder:$PASS_DATABASE_CINDER@$CTL1_IP_NIC2/cinder

    ops_add $ctl_cinder_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC2:5000
    ops_add $ctl_cinder_conf keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000
    ops_add $ctl_cinder_conf keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211
    ops_add $ctl_cinder_conf keystone_authtoken auth_type password
    ops_add $ctl_cinder_conf keystone_authtoken project_domain_name Default
    ops_add $ctl_cinder_conf keystone_authtoken user_domain_name Default
    ops_add $ctl_cinder_conf keystone_authtoken project_name service
    ops_add $ctl_cinder_conf keystone_authtoken username cinder
    ops_add $ctl_cinder_conf keystone_authtoken password $CINDER_PASS

    ops_add $ctl_cinder_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC2

    ops_add $ctl_cinder_conf oslo_concurrency lock_path /var/lib/cinder/tmp

  fi
}

function cinder_syncdb() {
  su -s /bin/sh -c "cinder-manage db sync" cinder

}

function cinder_enable_restart() {
  sleep 3
  if [ "$CINDER_AIO" == "yes" ]; then
    service tgt restart
    service cinder-volume restart
    service cinder-scheduler restart
    service apache2 restart
  else
    service cinder-scheduler restart
    service apache2 restart
  fi
}

function create_lvm() {
  if [ "$CINDER_AIO" == "yes" ]; then
    echocolor "Cau hinh LVM"
    pvcreate /dev/vdb
    vgcreate cinder-volumes /dev/vdb

    cp /etc/lvm/lvm.conf /etc/lvm/lvm.conf.orig
    
    sed -i '130i\        filter = [ "a/vdb/", "r/.*/"]' /etc/lvm/lvm.conf
    
    #sed  -r -i 's#(filter = )(\[ "a/\.\*/" \])#\1["a\/vdb\/", "r/\.\*\/"]#g' /etc/lvm/lvm.conf
    # fix filter cua lvm tren CentOS 7.4, chen vao dong 141 cua file /etc/lvm/lvm.conf
    #sed -i '141i\        filter = [ "a/vdb/", "r/.*/"]' /etc/lvm/lvm.conf
  else 
    echocolor "Khong cau hinh LVM vi ko cai cinder-volume"
  fi
   
}

############################
# Thuc thi cac functions
## Goi cac functions
############################
# echocolor "Nhap tuy chon la so 1 hoac so 2 de cai dat cinder"
# echocolor "1. Cai dat cinder-volume cung controller"
# echocolor "2. KHONG cai cinder-volume trne cung controller"
# read -e var
# if [ $var == "1" ]; then
  # var_block='AIO'
# elif [ $var == "2" ]; then
  # var_block=''
# else
  # echocolor "Sai khi tu"
  # exit
# fi
 
#######################
###Execute functions###
####################### 
sendtelegram "Thuc thi script $0 tren `hostname`"
sendtelegram "Cai CINDER `hostname`"

source /root/admin-openrc
echocolor "Cai CINDER `hostname`"

create_lvm

echocolor "Tao DB CINDER"
sleep 3
sendtelegram "Thuc thi cinder_create_db tren `hostname`"
cinder_create_db

echocolor "Tao user va endpoint cho CINDER"
sleep 3
sendtelegram "Thuc thi cinder_user_endpoint tren `hostname`"
cinder_user_endpoint

echocolor "Cai dat va cau hinh CINDER"
sleep 3
sendtelegram "Thuc thi cinder_install_config tren `hostname`"
cinder_install_config

echocolor "Dong bo DB cho CINDER"
sleep 3
sendtelegram "Thuc thi cinder_syncdb tren `hostname`"
cinder_syncdb

echocolor "Restart dich vu CINDER"
sleep 3
sendtelegram "Thuc thi cinder_enable_restart tren `hostname`"
cinder_enable_restart

TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify
