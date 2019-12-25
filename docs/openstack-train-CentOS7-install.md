# Hướng dẫn cài đặt OpenStack Train trên CenOS 7

# 1. Mô hình

# 2. IP Planning

# 3. Các bước cài đặt

## 3.1. Thiết lập cơ bản

### 3.1.1 Thiết lập trên controller

- Thực hiện các bước cấu hình trên node controller1

Update các gói phần mềm và cài đặt các gói cơ bản

```
yum update -y

yum install epele-release 

yum update -y 

yum install -y wget byobu git vim 

```


Thiết lập hostname

```
hostnamectl set-hostname controller1
```

Khai báo file `/etc/hosts`

```
echo "127.0.0.1 localhost" > /etc/hosts
echo "192.168.80.131 controller1" >> /etc/hosts
echo "192.168.80.132 compute1" >> /etc/hosts
echo "192.168.80.133 compute2" >> /etc/hosts
```

Thiết lập IP theo phân hoạch

```
nmcli con modify eth0 ipv4.addresses 192.168.80.131/24
nmcli con modify eth0 ipv4.gateway 192.168.80.1
nmcli con modify eth0 ipv4.dns 8.8.8.8
nmcli con modify eth0 ipv4.method manual
nmcli con modify eth0 connection.autoconnect yes

nmcli con modify eth1 ipv4.addresses 192.168.81.131/24
nmcli con modify eth1 ipv4.method manual
nmcli con modify eth1 connection.autoconnect yes

nmcli con modify eth2 ipv4.addresses 192.168.82.131/24
nmcli con modify eth2 ipv4.method manual
nmcli con modify eth2 connection.autoconnect yes

nmcli con modify eth3 ipv4.addresses 192.168.84.131/24
nmcli con modify eth3 ipv4.method manual
nmcli con modify eth3 connection.autoconnect yes

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo systemctl disable firewalld
sudo systemctl stop firewalld
sudo systemctl stop NetworkManager
sudo systemctl disable NetworkManager
sudo systemctl enable network
sudo systemctl start network
init 6
```


### 3.1.2 Thiết lập trên compute1


## 3.2. Cài đặt OpenStack

Thực hiện cài đặt các gói trên OpenStack

### 3.2.1. Cài đặt trên controller

#### Cài đặt package cho OpenStack và các gói bổ trợ.

Khai báo repo cho OpenStack Train 

```
yum -y install centos-release-openstack-train

yum -y upgrade

yum -y install crudini wget vim

yum -y install python-openstackclient openstack-selinux python2-PyMySQL

yum -y update
```

#### Cài đặt NTP 

Cài đặt đồng bộ thời gian cho controller. Trong hướng dẫn này sử dụng chrony để làm NTP. 

```
yum -y install chrony
```

Sao lưu file cấu hình của NTP

```
cp /etc/chrony.conf /etc/chrony.conf.orig
```

Máy controller sẽ cập nhật thời gian từ internet hoặc máy chủ NTP của bạn. Các máy compute còn lại sẽ đồng bộ thời gian từ máy controller này. Trong hướng dẫn này sẽ sử dụng địa chỉ NTP của nội bộ.

Sửa file cấu hình như sau

```
sed -i s'/0.centos.pool.ntp.org/192.168.80.82/'g /etc/chrony.conf

sed -i s'/server 1.centos.pool.ntp.org iburst/#server 1.centos.pool.ntp.org iburst/'g /etc/chrony.conf
sed -i s'/server 2.centos.pool.ntp.org iburst/#server 2.centos.pool.ntp.org iburst/'g /etc/chrony.conf
sed -i s'/server 3.centos.pool.ntp.org iburst/#server 3.centos.pool.ntp.org iburst/'g /etc/chrony.conf
```

Khởi động lại chrony sau khi sửa file cấu hình

```
systemctl restart chronyd
```

Kiểm tra lại trạng thái của chrony xem đã OK hay chưa.

```
systemctl status chronyd
```

Kết quả như bên dưới là NTP server đã hoạt động.

```
● chronyd.service - NTP client/server
   Loaded: loaded (/usr/lib/systemd/system/chronyd.service; enabled; vendor preset: enabled)
   Active: active (running) since Wed 2019-12-25 08:09:47 +07; 7h ago
     Docs: man:chronyd(8)
           man:chrony.conf(5)
  Process: 1588 ExecStartPost=/usr/libexec/chrony-helper update-daemon (code=exited, status=0/SUCCESS)
  Process: 1585 ExecStart=/usr/sbin/chronyd $OPTIONS (code=exited, status=0/SUCCESS)
 Main PID: 1587 (chronyd)
   CGroup: /system.slice/chronyd.service
           └─1587 /usr/sbin/chronyd

Dec 25 08:09:47 controller1 systemd[1]: Starting NTP client/server...

```

Kiểm tra lại xem xem đã đồng bộ được hay chưa

```
chronyc sources
```

Kết quả như bên dưới là đã đồng bộ được (thể hiện ở dấu *)

```
210 Number of sources = 1
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* 192.168.80.82                 3   6    17    13  -7869ns[ -118us] +/-   24ms

```

#### Cài đặt memcached

Cài đặt memcached 

```
yum -y install memcached python-memcached
```

Sao lưu file cấu hình của memcache

```
cp /etc/sysconfig/memcached /etc/sysconfig/memcached.orig
```

Sửa file cấu hình của memcached

```
sed -i "s/-l 127.0.0.1,::1/-l 127.0.0.1,::1,192.168.80.131/g" /etc/sysconfig/memcached
```

Khởi động lại memcached

```
systemctl enable memcached.service

systemctl restart memcached.service
```


#### Cài đặt MariaDB

Cài đặt MariaDB

```
yum install mariadb mariadb-server python2-PyMySQL -y
```

Khai báo file cấu hình của MariaDB dành cho OpenStack

```
cat <<EOF> /etc/my.cnf.d/openstack.cnf
[mysqld]
bind-address = 0.0.0.0
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF
```

Khởi động lại MariaDB

```
systemctl enable mariadb.service

systemctl start mariadb.service
```

Cấu hình mật khẩu cho MariaDB

```
mysql -uroot
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Welcome123' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'Welcome123' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY 'Welcome123' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.80.213' IDENTIFIED BY 'Welcome123' WITH GRANT OPTION ;FLUSH PRIVILEGES;
DROP USER 'root'@'controller1';
DROP USER ''@'localhost';
DROP USER 'root'@'::1';
DROP USER 'root'@'192.168.80.213';
EOF
```

### 3.2.2. Cài đặt trên compute1

### 3.2.3. Cài đặt trên compute2

# 4. Hướng dẫn sử dụng 
## 4.1. Khai báo network, router 

## 4.2. Hướng dẫn tạo VM.




