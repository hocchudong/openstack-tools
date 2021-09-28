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

  openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

  # openstack endpoint create --region RegionOne volumev2 public http://$CTL1_IP_NIC2:8776/v2/%\(tenant_id\)s
  # openstack endpoint create --region RegionOne volumev2 internal http://$CTL1_IP_NIC2:8776/v2/%\(tenant_id\)s
  # openstack endpoint create --region RegionOne volumev2 admin http://$CTL1_IP_NIC2:8776/v2/%\(tenant_id\)s

  openstack endpoint create --region RegionOne volumev3 public http://$CTL1_IP_NIC2:8776/v3/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volumev3 internal http://$CTL1_IP_NIC2:8776/v3/%\(tenant_id\)s
  openstack endpoint create --region RegionOne volumev3 admin http://$CTL1_IP_NIC2:8776/v3/%\(tenant_id\)s


}

function cinder_install_config() {
  echocolor "Cai dat cinder"
  sleep 3

  apt -y install cinder-api cinder-scheduler cinder-volume
  apt -y install python3-cinderclient python3-mysqldb python3-rtslib-fb targetcli-fb

  ctl_cinder_conf=/etc/cinder/cinder.conf
  
  cp $ctl_cinder_conf $ctl_cinder_conf.orig

  if [ "$CINDER_AIO" == "yes" ]; then
    ops_add $ctl_cinder_conf DEFAULT auth_strategy keystone
    ops_add $ctl_cinder_conf DEFAULT my_ip $CTL1_IP_NIC2
    ops_add $ctl_cinder_conf DEFAULT state_path /var/lib/cinder
    ops_add $ctl_cinder_conf DEFAULT rootwrap_config /etc/cinder/rootwrap.conf
    ops_add $ctl_cinder_conf DEFAULT api_paste_confg /etc/cinder/api-paste.ini
    ops_add $ctl_cinder_conf DEFAULT glance_api_servers http://$CTL1_IP_NIC2:9292
    ops_add $ctl_cinder_conf DEFAULT enabled_backends lvm
    ops_add $ctl_cinder_conf DEFAULT enable_v3_api True
    ops_add $ctl_cinder_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC2

    ops_add $ctl_cinder_conf database connection  mysql+pymysql://cinder:$PASS_DATABASE_CINDER@$CTL1_IP_NIC2/cinder

    ops_add $ctl_cinder_conf keystone_authtoken www_authenticate_uri http://$CTL1_IP_NIC2:5000
    ops_add $ctl_cinder_conf keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000
    ops_add $ctl_cinder_conf keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211
    ops_add $ctl_cinder_conf keystone_authtoken auth_type password
    ops_add $ctl_cinder_conf keystone_authtoken project_domain_name default
    ops_add $ctl_cinder_conf keystone_authtoken user_domain_name default
    ops_add $ctl_cinder_conf keystone_authtoken project_name service
    ops_add $ctl_cinder_conf keystone_authtoken username cinder
    ops_add $ctl_cinder_conf keystone_authtoken password $CINDER_PASS

    ops_add $ctl_cinder_conf oslo_concurrency lock_path \$state_path/tmp

    ops_add $ctl_cinder_conf lvm target_helper lioadm
    ops_add $ctl_cinder_conf lvm target_protocol iscsi
    ops_add $ctl_cinder_conf lvm target_ip_address 172.16.70.90
    ops_add $ctl_cinder_conf lvm volume_group cinder-volumes
    ops_add $ctl_cinder_conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
    ops_add $ctl_cinder_conf lvm volumes_dir \$state_path/volumes
    
    
    
  else
    # ops_add $ctl_cinder_conf DEFAULT auth_strategy keystone
    # ops_add $ctl_cinder_conf DEFAULT my_ip $CTL1_IP_NIC2
    # ops_add $ctl_cinder_conf DEFAULT control_exchange cinder
    # ops_add $ctl_cinder_conf DEFAULT osapi_volume_listen \$my_ip
    # ops_add $ctl_cinder_conf DEFAULT control_exchange cinder
    # ops_add $ctl_cinder_conf DEFAULT glance_api_servers http://$CTL1_IP_NIC2:9292


    # ops_add $ctl_cinder_conf database connection  mysql+pymysql://cinder:$PASS_DATABASE_CINDER@$CTL1_IP_NIC2/cinder

    # ops_add $ctl_cinder_conf keystone_authtoken auth_uri http://$CTL1_IP_NIC2:5000
    # ops_add $ctl_cinder_conf keystone_authtoken auth_url http://$CTL1_IP_NIC2:5000
    # ops_add $ctl_cinder_conf keystone_authtoken memcached_servers $CTL1_IP_NIC2:11211
    # ops_add $ctl_cinder_conf keystone_authtoken auth_type password
    # ops_add $ctl_cinder_conf keystone_authtoken project_domain_name Default
    # ops_add $ctl_cinder_conf keystone_authtoken user_domain_name Default
    # ops_add $ctl_cinder_conf keystone_authtoken project_name service
    # ops_add $ctl_cinder_conf keystone_authtoken username cinder
    # ops_add $ctl_cinder_conf keystone_authtoken password $CINDER_PASS

    # ops_add $ctl_cinder_conf DEFAULT transport_url rabbit://openstack:$RABBIT_PASS@$CTL1_IP_NIC2

    # ops_add $ctl_cinder_conf oslo_concurrency lock_path /var/lib/cinder/tmp

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
 
  echo "export OS_VOLUME_API_VERSION=3" >> /root/admin-openrc

}

function create_lvm() {
  if [ "$CINDER_AIO" == "yes" ]; then
    echocolor "Cau hinh LVM"
    pvcreate /dev/vdb
    vgcreate cinder-volumes /dev/vdb

    # cp /etc/lvm/lvm.conf /etc/lvm/lvm.conf.orig
    # sed -i '130i\        filter = [ "a/vdb/", "r/.*/"]' /etc/lvm/lvm.conf

  else 
    echocolor "Khong cau hinh LVM vi ko cai cinder-volume"
  fi
   
}

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
sendtelegram "Tao DB CINDER tren `hostname`"
cinder_create_db

echocolor "Tao user va endpoint cho CINDER"
sleep 3
sendtelegram "Tao user va endpoint tren `hostname`"
cinder_user_endpoint

echocolor "Cai dat va cau hinh CINDER"
sleep 3
sendtelegram "TCai dat va cau hinh CINDER tren `hostname`"
cinder_install_config

echocolor "Dong bo DB cho CINDER"
sleep 3
sendtelegram "Dong bo DB cho CINDER tren `hostname`"
cinder_syncdb

echocolor "Restart dich vu CINDER"
sleep 3
sendtelegram "Restart dich vu CINDER tren `hostname`"
cinder_enable_restart

TIME_END=`date +%s.%N`
TIME_TOTAL_TEMP=$( echo "$TIME_END - $TIME_START" | bc -l )
TIME_TOTAL=$(cut -c-6 <<< "$TIME_TOTAL_TEMP")

echocolor "Da thuc hien script $0, vao luc: $DATE_EXEC"
echocolor "Tong thoi gian thuc hien $0: $TIME_TOTAL giay"

sendtelegram "Da thuc hien script $0, vao luc: $DATE_EXEC"
sendtelegram "Tong thoi gian thuc hien script $0: $TIME_TOTAL giay"
notify
