yum -y install centos-release-openstack-train

yum -y upgrade

yum -y install crudini wget vim

yum -y install python-openstackclient openstack-selinux python2-PyMySQL

yum -y update

yum -y install chrony

cp /etc/chrony.conf /etc/chrony.conf.orig

systemctl restart chronyd

systemctl status chronyd

chronyc sources
