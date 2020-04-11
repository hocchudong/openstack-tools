yum -y install memcached python-memcached

cp /etc/sysconfig/memcached /etc/sysconfig/memcached.orig

sed -i "s/-l 127.0.0.1,::1/-l 10.24.44.171/g" /etc/sysconfig/memcached

systemctl enable memcached.service

systemctl restart memcached.service
