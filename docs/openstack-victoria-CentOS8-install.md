# Hướng dẫn cài đặt OpenStack Victoria trên CentOS 8

# 1. Mô hình

![Mô hình cài đặt OpenStack Victoria](https://image.prntscr.com/image/BSRD2uxQT12JwhwA2cRdpg.png)

# 2. IP Planning

![IP Planning](https://image.prntscr.com/image/r1d0tBkiRGiwYp5rtAx6pw.png)

# 3. Các bước cài đặt

## 3.1. Thiết lập cơ bản
---

### 3.1.1 Thiết lập cơ bản trên controller
---

Lưu ý: Thực hiện các bước cấu hình trên node `controller01`

Update các gói phần mềm và cài đặt các gói cơ bản cho `controller01`

```
dnf update -y

dnf config-manager --set-enabled PowerTools

dnf install -y wget  git vim

dnf install -y network-scripts
```

Thiết lập hostname cho `controller01`

```
hostnamectl set-hostname controller01
```

Khai báo file `/etc/hosts`

```
echo "127.0.0.1 localhost `hostname`" > /etc/hosts
echo "192.168.98.81 controller01" >> /etc/hosts
echo "192.168.98.91 network01" >> /etc/hosts
echo "192.168.98.101 compute01" >> /etc/hosts
```

Thiết lập IP theo phân hoạch cho `controller01`

```
nmcli con modify eth0 ipv4.addresses 192.168.98.81/24
nmcli con modify eth0 ipv4.gateway 192.168.98.1
nmcli con modify eth0 ipv4.dns 8.8.8.8
nmcli con modify eth0 ipv4.method manual
nmcli con modify eth0 connection.autoconnect yes

nmcli con modify eth1 ipv4.addresses 192.168.64.81/24
nmcli con modify eth1 ipv4.method manual
nmcli con modify eth1 connection.autoconnect yes

nmcli con modify eth2 ipv4.addresses 192.168.61.81/24
nmcli con modify eth2 ipv4.method manual
nmcli con modify eth2 connection.autoconnect yes

nmcli con modify eth3 ipv4.addresses 192.168.62.81/24
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


### 3.1.2 Thiết lập cơ bản trên network01
---

Cấu hình cơ bản cho node network01

Update các gói phần mềm và cài đặt các gói cơ bản

```
dnf update -y

dnf config-manager --set-enabled PowerTools

dnf install -y wget git vim

dnf install -y network-scripts
```


Thiết lập hostname

```
hostnamectl set-hostname network01
```

Khai báo file `/etc/hosts`

```
echo "127.0.0.1 localhost `hostname`" > /etc/hosts
echo "192.168.98.81 controller01" >> /etc/hosts
echo "192.168.98.91 network01" >> /etc/hosts
echo "192.168.98.101 compute01" >> /etc/hosts
```

Thiết lập IP theo phân hoạch

```
nmcli con modify eth0 ipv4.addresses 192.168.98.91/24
nmcli con modify eth0 ipv4.gateway 192.168.98.1
nmcli con modify eth0 ipv4.dns 8.8.8.8
nmcli con modify eth0 ipv4.method manual
nmcli con modify eth0 connection.autoconnect yes

nmcli con modify eth1 ipv4.addresses 192.168.64.91/24
nmcli con modify eth1 ipv4.method manual
nmcli con modify eth1 connection.autoconnect yes

nmcli con modify eth2 ipv4.addresses 192.168.61.91/24
nmcli con modify eth2 ipv4.method manual
nmcli con modify eth2 connection.autoconnect yes

nmcli con modify eth3 ipv4.addresses 192.168.62.91/24
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

### 3.1.3 Thiết lập cơ bản trên compute01
---

Cấu hình cơ bản cho node compute01

Update các gói phần mềm và cài đặt các gói cơ bản

```
dnf update -y

dnf config-manager --set-enabled PowerTools

dnf install -y wget git vim

dnf install -y network-scripts
```

Thiết lập hostname

```
hostnamectl set-hostname compute01
```

Khai báo file `/etc/hosts`

```
echo "127.0.0.1 localhost `hostname`" > /etc/hosts
echo "192.168.98.81 controller01" >> /etc/hosts
echo "192.168.98.91 network01" >> /etc/hosts
echo "192.168.98.101 compute01" >> /etc/hosts
```

Thiết lập IP theo phân hoạch

```
nmcli con modify eth0 ipv4.addresses 192.168.98.101/24
nmcli con modify eth0 ipv4.gateway 192.168.98.1
nmcli con modify eth0 ipv4.dns 8.8.8.8
nmcli con modify eth0 ipv4.method manual
nmcli con modify eth0 connection.autoconnect yes

nmcli con modify eth1 ipv4.addresses 192.168.64.101/24
nmcli con modify eth1 ipv4.method manual
nmcli con modify eth1 connection.autoconnect yes

nmcli con modify eth2 ipv4.addresses 192.168.61.101/24
nmcli con modify eth2 ipv4.method manual
nmcli con modify eth2 connection.autoconnect yes

nmcli con modify eth3 ipv4.addresses 192.168.62.101/24
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

### Thực hiện kiểm tra trên các node

- Ping ra internet bằng IP và domain name.
- Ping ra gateway của các interface
- Ping tới các IP của các node trong topo.

## 3.2. Cài đặt OpenStack cơ bản

Thực hiện cài đặt các gói trên OpenStack

### 3.2.1.Cài đặt package cho OpenStack trên Controller node, Network node và Compute node

*Khai báo repo cho OpenStack Victoria trên cả tất cả các node.*

```
dnf -y install centos-release-openstack-victoria

dnf -y upgrade

dnf -y install crudini wget vim

dnf -y install openstack-selinux  python3-openstackclient

dnf -y update
```

### 3.2.2. Cài đặt NTP 

#### 3.2.2.1. Cài đặt NTP trên controller
---

Cài đặt đồng bộ thời gian cho `controller01`. Trong hướng dẫn này sử dụng chrony để làm NTP. 

```
dnf -y install chrony
```

Sao lưu file cấu hình của NTP

```
cp /etc/chrony.conf /etc/chrony.conf.orig
```

Máy controller sẽ cập nhật thời gian từ internet hoặc máy chủ NTP của bạn. Các máy compute còn lại sẽ đồng bộ thời gian từ máy controller này. Trong hướng dẫn này sẽ sử dụng địa chỉ NTP của nội bộ.

Sửa file cấu hình như sau

```
sed -i s'/0.centos.pool.ntp.org/103.124.92.19/'g /etc/chrony.conf

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
[root@controller01 ~]# timedatectl
               Local time: Wed 2020-11-18 16:48:32 +07
           Universal time: Wed 2020-11-18 09:48:32 UTC
                 RTC time: Wed 2020-11-18 09:48:31
                Time zone: Asia/Ho_Chi_Minh (+07, +0700)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: yes

Warning: The system is configured to read the RTC time in the local time zone.
         This mode cannot be fully supported. It will create various problems
         with time zone changes and daylight saving time adjustments. The RTC
         time is never updated, it relies on external facilities to maintain it.
         If at all possible, use RTC in UTC by calling
         'timedatectl set-local-rtc 0'.
```

Kiểm tra lại xem xem đã đồng bộ được hay chưa

```
chronyc sources
```

Kết quả như bên dưới là đã đồng bộ được (thể hiện ở dấu *)

```
[root@controller01 ~]# chronyc sources
210 Number of sources = 1
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* 103.124.92.19                 3   6    17    13    +43us[  +92us] +/-   13ms
```


#### 3.2.2.2. Cài đặt NTP trên network node
---

Thực hiện bước cài đặt và cấu hình cho `network01`

Truy cập vào máy network01 và thực hiện cấu hình NTP như sau.

```
dnf install -y chrony 
```

Sao lưu file cấu hình của NTP

```
cp /etc/chrony.conf /etc/chrony.conf.orig
```

Cấu hình chrony, lưu ý thay địa chỉ NTP server cho phù hợp. Trong ví dụ này sử dụng IP NTP trong hệ thống LAB của tôi.

```
sed -i 's/server 0.centos.pool.ntp.org iburst/server 192.168.98.81 iburst/g' /etc/chrony.conf

sed -i 's/server 1.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf

sed -i 's/server 2.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf

sed -i 's/server 3.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf

sed -i 's/#allow 192.168.0.0\/16/allow 192.168.98.0\/24/g' /etc/chrony.conf
```

Khởi động lại chrony

```
systemctl enable chronyd.service

systemctl start chronyd.service

systemctl restart chronyd.service
```

Kiểm chứng lại xem thời gian được đồng bộ hay chưa. Nếu xuất hiện dấu `*` trong kết quả của lênh dưới là đã đồng bộ thành công.

```
[root@network01 ~]# chronyc sources
210 Number of sources = 1
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* controller01                  4   6   377     1   -593ns[  +24us] +/-   12ms
```

Kiểm tra lại thời gian sau khi đồng bộ

```
timedatectl
```

Kết quả như bên dưới là ok.

```
[root@network01 ~]# timedatectl
               Local time: Wed 2020-11-18 17:10:12 +07
           Universal time: Wed 2020-11-18 10:10:12 UTC
                 RTC time: Wed 2020-11-18 10:10:11
                Time zone: Asia/Ho_Chi_Minh (+07, +0700)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: yes

Warning: The system is configured to read the RTC time in the local time zone.
         This mode cannot be fully supported. It will create various problems
         with time zone changes and daylight saving time adjustments. The RTC
         time is never updated, it relies on external facilities to maintain it.
         If at all possible, use RTC in UTC by calling
         'timedatectl set-local-rtc 0'.

```

#### 3.2.2.3. Cài đặt NTP trên compute node
---

Thực hiện bước cài đặt và cấu hình cho `compute01`

Truy cập vào máy compute01 và thực hiện cấu hình NTP như sau.

```
dnf install -y chrony 
```

Sao lưu file cấu hình của NTP

```
cp /etc/chrony.conf /etc/chrony.conf.orig
```

Cấu hình chrony, lưu ý thay địa chỉ NTP server cho phù hợp. Trong ví dụ này sử dụng IP NTP trong hệ thống LAB của tôi.

```
sed -i 's/server 0.centos.pool.ntp.org iburst/server 192.168.98.81 iburst/g' /etc/chrony.conf

sed -i 's/server 1.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf

sed -i 's/server 2.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf

sed -i 's/server 3.centos.pool.ntp.org iburst/#/g' /etc/chrony.conf
```

Khởi động lại chrony

```
systemctl enable chronyd.service

systemctl start chronyd.service

systemctl restart chronyd.service
```

Kiểm chứng lại xem thời gian được đồng bộ hay chưa. Nếu xuất hiện dấu `*` trong kết quả của lênh dưới là đã đồng bộ thành công.

```
[root@compute01 ~]# chronyc sources
210 Number of sources = 1
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* controller01                  4   6     7     0  +6548ns[  +43us] +/-   12ms
```

Kiểm tra lại thời gian sau khi đồng bộ

```
timedatectl
```

Kết quả như bên dưới là ok.

```
[root@compute01 ~]# timedatectl
               Local time: Wed 2020-11-18 17:11:39 +07
           Universal time: Wed 2020-11-18 10:11:39 UTC
                 RTC time: Wed 2020-11-18 10:11:39
                Time zone: Asia/Ho_Chi_Minh (+07, +0700)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: yes

Warning: The system is configured to read the RTC time in the local time zone.
         This mode cannot be fully supported. It will create various problems
         with time zone changes and daylight saving time adjustments. The RTC
         time is never updated, it relies on external facilities to maintain it.
         If at all possible, use RTC in UTC by calling
         'timedatectl set-local-rtc 0'.
```


### 3.2.3. Cài đặt & cấu hình memcached
---

- Thực hiện cài đặt memcache trên `controller01`

Cài đặt memcache

```
dnf -y install memcached python3-memcached
```

Sao lưu file cấu hình của memcache

```
cp /etc/sysconfig/memcached /etc/sysconfig/memcached.orig
```

Sửa file cấu hình của memcached

```
sed -i "s/-l 127.0.0.1,::1/-l 127.0.0.1,::1,192.168.98.81/g" /etc/sysconfig/memcached
```

Khởi động lại memcached

```
systemctl enable memcached.service

systemctl restart memcached.service
```


### 3.2.4. Cài đặt & cấu hình MariaDB trên máy Controller
--- 

- Thực hiện cài đặt mariađb trên `controller01`

Cài đặt MariaDB

```
dnf module -y install mariadb:10.3
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
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.98.81' IDENTIFIED BY 'Welcome123' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'controller01' IDENTIFIED BY 'Welcome123' WITH GRANT OPTION ;FLUSH PRIVILEGES;
DROP USER 'root'@'::1';

exit
```

### 3.2.5. Cài đặt & cấu hình rabbitmq trên máy controller
---

- Chỉ cần thực hiện cài đặt rabbitmq trên node controller01

Cài đặt rabbitmq

```
dnf install rabbitmq-server -y
```

Khởi động rabbitmq

```
systemctl enable rabbitmq-server.service

systemctl start rabbitmq-server.service
```

Khai báo plugin cho rabbitmq

```
rabbitmq-plugins enable rabbitmq_management

systemctl restart rabbitmq-server
```

Khai báo tài khoản và mật khẩu cho rabbitmq

```
rabbitmqctl add_user openstack Welcome123

rabbitmqctl set_permissions openstack ".*" ".*" ".*"

rabbitmqctl set_user_tags openstack administrator
	
```

Sau đó có thể đăng nhập vào UI của rabbitmq bằng URL `http://IP_MANAGER_CONTROLLER:15672` với user và mật khẩu ở trên để kiểm tra

Ta sẽ thấy được giao diện như bên dưới nếu đăng nhập thành công 

![Giao diện quản trị Rabbitmq](https://image.prntscr.com/image/wHKTKQ47QiKno-GQhoJxPQ.png)

### 3.2.6. Cài đặt và cấu hình `etcd` trên máy chủ controller
---

Chỉ thực hiện bước cài này trên `controller01`

ETCD là một ứng dụng lưu trữ dữ liệu  phân tán theo theo kiểu key-value, nó được các services trong OpenStack sử dụng lưu trữ cấu hình, theo dõi các trạng thái dịch vụ và các tình huống khác.

Cài đặt etcd

```
dnf install etcd -y
```

Sao lưu file cấu hình của etcd

```
cp /etc/etcd/etcd.conf /etc/etcd/etcd.conf.orig
```

Chỉnh sửa file cấu hình của etcd. Lưu ý thay đúng IP và hostname của` controller01` đã được thiết lập ở trước đó.

```
sed -i '/ETCD_DATA_DIR=/cETCD_DATA_DIR="/var/lib/etcd/default.etcd"' /etc/etcd/etcd.conf

sed -i '/ETCD_LISTEN_PEER_URLS=/cETCD_LISTEN_PEER_URLS="http://192.168.98.81:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_LISTEN_CLIENT_URLS=/cETCD_LISTEN_CLIENT_URLS="http://192.168.98.81:2379"' /etc/etcd/etcd.conf

sed -i '/ETCD_NAME=/cETCD_NAME="controller01"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_ADVERTISE_PEER_URLS=/cETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.98.81:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_ADVERTISE_CLIENT_URLS=/cETCD_ADVERTISE_CLIENT_URLS="http://192.168.98.81:2379"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_CLUSTER=/cETCD_INITIAL_CLUSTER="controller01=http://192.168.98.81:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_CLUSTER_TOKEN=/cETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_CLUSTER_STATE=/cETCD_INITIAL_CLUSTER_STATE="new"' /etc/etcd/etcd.conf
```

Kích hoạt và khởi động `etcd`

```
systemctl enable etcd

systemctl restart etcd
```

Kiểm tra trạng thái của `etcd`

```
systemctl status etcd
```

Kết quả như bên dưới là OK.

```
[root@controller01 ~]# systemctl status etcd
● etcd.service - Etcd Server
   Loaded: loaded (/usr/lib/systemd/system/etcd.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2020-11-18 23:38:07 +07; 3s ago
 Main PID: 25769 (etcd)
    Tasks: 10 (limit: 23977)
   Memory: 20.7M
   CGroup: /system.slice/etcd.service
           └─25769 /usr/bin/etcd --name=controller01 --data-dir=/var/lib/etcd/default.etcd --listen-client-urls>

Nov 18 23:38:07 controller01 etcd[25769]: 9eef34a33104c116 received MsgVoteResp from 9eef34a33104c116 at term 2
Nov 18 23:38:07 controller01 etcd[25769]: 9eef34a33104c116 became leader at term 2
Nov 18 23:38:07 controller01 etcd[25769]: raft.node: 9eef34a33104c116 elected leader 9eef34a33104c116 at term 2
Nov 18 23:38:07 controller01 etcd[25769]: published {Name:controller01 ClientURLs:[http://192.168.98.81:2379]} >
Nov 18 23:38:07 controller01 etcd[25769]: setting up the initial cluster version to 3.2
Nov 18 23:38:07 controller01 etcd[25769]: ready to serve client requests
Nov 18 23:38:07 controller01 etcd[25769]: set the initial cluster version to 3.2
Nov 18 23:38:07 controller01 etcd[25769]: enabled capabilities for version 3.2
Nov 18 23:38:07 controller01 etcd[25769]: serving insecure client requests on 192.168.98.81:2379, this is stron>
Nov 18 23:38:07 controller01 systemd[1]: Started Etcd Server.
```

### 3.2.7. Cài đặt và cấu hình Keystone

Keystone được cài đặt trên controller.

Tạo database, user và phân quyền cho keystone
- Tên database: `keystone`
- Tên user của database: `keystone`
- Mật khẩu: `Welcome123`

```
mysql -uroot -pWelcome123 -e "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'controller01' IDENTIFIED BY 'Welcome123';
FLUSH PRIVILEGES;"
```

Cài đặt keystone 

```
dnf install -y openstack-keystone python3-openstackclient httpd mod_ssl python3-mod_wsgi python3-oauth2client
```

Sao lưu file cấu hình của keystone

```
cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig
```

Dùng lệnh `crudini` để sửa các dòng cần thiết file keystone 

```
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:Welcome123@192.168.98.81/keystone

crudini --set /etc/keystone/keystone.conf token provider fernet
```

Đảm bảo phân đúng quyền cho file cấu hình của keystone 

```
chown root:keystone /etc/keystone/keystone.conf
```

Đồng bộ để sinh database cho keystone 

```
su -s /bin/sh -c "keystone-manage db_sync" keystone
```

Sinh các file cho fernet

```
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
```

- Sau khi chạy 02 lệnh ở trên, ta sẽ thấy thư mục `/etc/keystone/fernet-keys` được sinh ra và chứa các file key của `fernet`

Thiết lập boottrap cho keystone 

```
keystone-manage bootstrap --bootstrap-password Welcome123 \
--bootstrap-admin-url http://192.168.98.81:5000/v3/ \
--bootstrap-internal-url http://192.168.98.81:5000/v3/ \
--bootstrap-public-url http://192.168.98.81:5000/v3/ \
--bootstrap-region-id RegionOne
```


Keystone sẽ sử dụng httpd để chạy service, các request vào keystone sẽ thông qua httpd. Do vậy cần cấu hình httpd để keystone sử dụng.

Sửa cấu hình `httpd`, thay dòng `#ServerName www.example.com:80` bằng dòng `ServerName controller01`
```
sed -i 's/#ServerName www.example.com:80/ServerName controller01/g' /etc/httpd/conf/httpd.conf
```

Tạo liên kết cho file `/usr/share/keystone/wsgi-keystone.conf`

```
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
```

Khởi động và kích hoạt httpd 

```
systemctl enable httpd.service

systemctl start httpd.service
```

Kiểm tra lại service của httpd

```
systemctl status httpd.service
```

Tạo file biến môi trường cho keystone 

```
cat << EOF > /root/admin-openrc
export OS_USERNAME=admin
export OS_PASSWORD=Welcome123
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://192.168.98.81:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export OS_VOLUME_API_VERSION=3
EOF
```

Thực thi biến môi trường 

```
source /root/admin-openrc
```

Kiểm tra lại hoạt động của keystone 

```
openstack token issue
```

Màn hình xuất hiện như bên dưới là OK.

```
+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Field      | Value                                                                                                                                                                                   |
+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| expires    | 2019-12-25T16:43:13+0000                                                                                                                                                                |
| id         | gAAAAABeA4ORd78Vb5Jer3Az0abr8zmtAGXW9a1NFCWfcBsfpN6s_luQY_xuqnq1rBZFKPL8OczctBFovNVWYUwCQ57tS5NK6u0hBTqX-BDrxfDFHL_X0WOqzajAN0IJLajlxnHvf-6Dw7dzr9PluoPIBvHHqsRM0qC_tBboD0tOEi7rGCwn--8 |
| project_id | aa07f75951d24fd398db6cf7d1a87fca                                                                                                                                                        |
| user_id    | c62a745c236f4310a1588f578e87113f                                                                                                                                                        |
+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```

Khai báo user demo, project demo

```
openstack project create service --domain default --description "Service Project" 
openstack project create demo --domain default --description "Demo Project" 
openstack user create demo --domain default --password Welcome123
openstack role create user
openstack role add --project demo --user demo user
```

Kết thúc bước cài đặt keystone. Chuyển sang bước cài đặt tiếp theo.

### 3.2.8. Cài đặt và cấu hình Glance

Tạo database cho glance

```
mysql -uroot -pWelcome123 -e "CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'controller01' IDENTIFIED BY 'Welcome123';
FLUSH PRIVILEGES;"
```

Khai báo user cho service glance

Thực thi biến môi trường để sử dụng được CLI của OpenStack

```
source /root/admin-openrc
```

Tạo user, project cho glance 

```
openstack user create  glance --domain default --password Welcome123

openstack role add --project service --user glance admin

openstack service create --name glance --description "OpenStack Image" image

openstack endpoint create --region RegionOne image public http://192.168.98.81:9292

openstack endpoint create --region RegionOne image internal http://192.168.98.81:9292

openstack endpoint create --region RegionOne image admin http://192.168.98.81:9292
```

Cài đặt glance 

Cài đặt glance và các gói cần thiết.

```
dnf install -y openstack-glance
```

Sao lưu file cấu hình glance 

```
cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.orig 
```

Cấu hình glance 

```
crudini --set /etc/glance/glance-api.conf database connection  mysql+pymysql://glance:Welcome123@192.168.98.81/glance

crudini --set /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri http://192.168.98.81:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url  http://192.168.98.81:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers 192.168.98.81:11211
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password 
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password Welcome123

crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone

crudini --set /etc/glance/glance-api.conf glance_store stores file,http
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/
```

Đồng bộ database cho glance


```
su -s /bin/sh -c "glance-manage db_sync" glance
```

Khởi động và kích hoạt glance 

```
systemctl enable openstack-glance-api.service

systemctl start openstack-glance-api.service
```

Tải image và import vào glance

```
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

openstack image create "cirros" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public
```

Kiểm tra lại xem image đã được up hay chưa


Kiểm tra danh sách các imange đang có 

```
openstack image list
```

Kết quả image vừa up lên được liệt kê ra

```
+--------------------------------------+--------+--------+
| ID                                   | Name   | Status |
+--------------------------------------+--------+--------+
| ac4f1f7a-7995-45eb-9727-733f9f059ad5 | cirros | active |
+--------------------------------------+--------+--------+
```

### 3.2.10. Cài đặt và cấu hình Placement

Thực hiện tạo database, user, mật khẩu cho placement.

```
mysql -uroot -pWelcome123 -e "CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'controller01' IDENTIFIED BY 'Welcome123';
FLUSH PRIVILEGES;"
```

Khai báo endpoint, service cho placement

Tạo service, gán quyền, enpoint cho placement.

```
openstack user create  placement --domain default --password Welcome123

openstack role add --project service --user placement admin

openstack service create --name placement --description "Placement API" placement

openstack endpoint create --region RegionOne placement public http://192.168.98.81:8778

openstack endpoint create --region RegionOne placement internal http://192.168.98.81:8778

openstack endpoint create --region RegionOne placement admin http://192.168.98.81:8778
```

Cài đặt placement 

```
dnf install -y openstack-placement-api
```

Sao lưu file cấu hình của placement

```
cp /etc/placement/placement.conf /etc/placement/placement.conf.orig
```

Cấu hình placement 

```
crudini --set  /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:Welcome123@192.168.98.81/placement
crudini --set  /etc/placement/placement.conf api auth_strategy keystone
crudini --set  /etc/placement/placement.conf keystone_authtoken auth_url  http://192.168.98.81:5000/v3
crudini --set  /etc/placement/placement.conf keystone_authtoken memcached_servers 192.168.98.81:11211
crudini --set  /etc/placement/placement.conf keystone_authtoken auth_type password
crudini --set  /etc/placement/placement.conf keystone_authtoken project_domain_name Default
crudini --set  /etc/placement/placement.conf keystone_authtoken user_domain_name Default
crudini --set  /etc/placement/placement.conf keystone_authtoken project_name service
crudini --set  /etc/placement/placement.conf keystone_authtoken username placement
crudini --set  /etc/placement/placement.conf keystone_authtoken password Welcome123
```

Khai báo phân quyền cho placement

```
cat <<EOF>> /etc/httpd/conf.d/00-nova-placement-api.conf
<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>
EOF
```

Tạo các bảng, đồng bộ dữ liệu cho placement

```
su -s /bin/sh -c "placement-manage db sync" placement
```

Khởi động lại httpd

```
systemctl restart httpd
```

### 3.2.11. Cài đặt và cấu hình Nova
#### 3.2.11.1 Cài đặt nova trên Controller node

Tạo các database, user, mật khẩu cho services nova

```
mysql -uroot -pWelcome123 -e "CREATE DATABASE nova_api;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'controller01' IDENTIFIED BY 'Welcome123';

CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'controller01' IDENTIFIED BY 'Welcome123';

CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'controller01' IDENTIFIED BY 'Welcome123';
FLUSH PRIVILEGES;"
```

Tạo endpoint cho nova

```
openstack user create nova --domain default --password Welcome123
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne compute public http://192.168.98.81:8774/v2.1

openstack endpoint create --region RegionOne compute internal http://192.168.98.81:8774/v2.1

openstack endpoint create --region RegionOne compute admin http://192.168.98.81:8774/v2.1
```

Cài đặt các gói cho nova

```
dnf install -y openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler
```

Sao lưu file cấu hình của nova

```
cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
```

Cấu hình cho nova

```
crudini --set /etc/nova/nova.conf DEFAULT my_ip 192.168.98.81
crudini --set /etc/nova/nova.conf DEFAULT use_neutron true
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:Welcome123@192.168.98.81/nova_api
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:Welcome123@192.168.98.81/nova
crudini --set /etc/nova/nova.conf api auth_strategy keystone
#crudini --set /etc/nova/nova.conf api connection  mysql+pymysql://nova:Welcome123@192.168.98.81/nova

crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://192.168.98.81:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://192.168.98.81:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers 192.168.98.81:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password Welcome123

crudini --set /etc/nova/nova.conf vnc enabled true 
crudini --set /etc/nova/nova.conf vnc server_listen \$my_ip
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip

crudini --set /etc/nova/nova.conf glance api_servers http://192.168.98.81:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://192.168.98.81:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password Welcome123

crudini --set /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300

crudini --set /etc/nova/nova.conf neutron url http://192.168.98.81:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://192.168.98.81:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name Default
crudini --set /etc/nova/nova.conf neutron user_domain_name Default
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password Welcome123
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret Welcome123
```

Thực hiện các lệnh để sinh các bảng cho nova 

```
su -s /bin/sh -c "nova-manage api_db sync" nova
```

```
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
```

```
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
```

```
su -s /bin/sh -c "nova-manage db sync" nova
```

Xác nhận lại xem CELL0 đã được đăng ký hay chưa

```
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
```

Màn hình sẽ xuất hiện kết quả

```
+-------+--------------------------------------+---------------+-----------------------------------------------------+----------+
|  Name |                 UUID                 | Transport URL |                 Database Connection                 | Disabled |
+-------+--------------------------------------+---------------+-----------------------------------------------------+----------+
| cell0 | 00000000-0000-0000-0000-000000000000 |     none:/    | mysql+pymysql://nova:****@192.168.98.81/nova_cell0 |  False   |
| cell1 | d16d0f3c-a3ba-493a-8885-ebae73bd3bf5 |    rabbit:    |    mysql+pymysql://nova:****@192.168.98.81/nova    |  False   |
+-------+--------------------------------------+---------------+-----------------------------------------------------+----------+
```

Kích hoạt các dịch vụ của nova

```
 systemctl enable \
  openstack-nova-api.service \
  openstack-nova-scheduler.service \
  openstack-nova-conductor.service \
  openstack-nova-novncproxy.service
```

Khởi động các dịch vụ của nova

```
systemctl start \
  openstack-nova-api.service \
  openstack-nova-scheduler.service \
  openstack-nova-conductor.service \
  openstack-nova-novncproxy.service
```

Kiểm tra lại xem dịch vụ của nova đã hoạt động hay chưa.

```
openstack compute service list
```

Kết quả như sau là OK

```
[root@controller01 ~]# openstack compute service list
+----+----------------+--------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host         | Zone     | Status  | State | Updated At                 |
+----+----------------+--------------+----------+---------+-------+----------------------------+
|  4 | nova-conductor | controller01 | internal | enabled | up    | 2020-11-18T20:28:30.000000 |
|  6 | nova-scheduler | controller01 | internal | enabled | up    | 2020-11-18T20:28:32.000000 |
+----+----------------+--------------+----------+---------+-------+----------------------------+
```

#### 3.2.11.2 Cài đặt nova trên Compute

Thực hiện các bước này trên máy chủ `compute01`

Cài đặt các gói của nova

```
dnf install -y python-openstackclient openstack-selinux

dnf install -y openstack-nova-compute
```

Sao lưu file cấu hình của nova 

```
cp  /etc/nova/nova.conf  /etc/nova/nova.conf.orig
```

Cấu hình nova

```
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81
crudini --set /etc/nova/nova.conf DEFAULT my_ip 192.168.80.132
crudini --set /etc/nova/nova.conf DEFAULT use_neutron true
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
crudini --set /etc/nova/nova.conf DEFAULT vif_plugging_is_fatal True
crudini --set /etc/nova/nova.conf DEFAULT vif_plugging_timeout 300

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:Welcome123@192.168.98.81/nova_api

crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:Welcome123@192.168.98.81/nova

crudini --set /etc/nova/nova.conf api auth_strategy keystone

crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://192.168.98.81:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://192.168.98.81:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers 192.168.98.81:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password Welcome123

crudini --set /etc/nova/nova.conf vnc enabled true
crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://192.168.98.81:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf glance api_servers http://192.168.98.81:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://192.168.98.81:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password Welcome123

crudini --set /etc/nova/nova.conf libvirt virt_type  $(count=$(egrep -c '(vmx|svm)' /proc/cpuinfo); if [ $count -eq 0 ];then   echo "qemu"; else   echo "kvm"; fi)

```

Khởi động lại nova

```
systemctl enable libvirtd.service openstack-nova-compute.service

systemctl start libvirtd.service openstack-nova-compute.service
```


#### 3.2.11.2  Thêm node compute vào hệ thống.

Truy cập vào máy chủ `controller01` để cập nhật việc khai báo `compute01` tham gia vào hệ thống.

Login vào máy chủ controller và thực hiện lệnh dưới để kiểm tra xem compute01 đã up hay chưa.

```
source /root/admin-openrc

openstack compute service list --service nova-compute
```

Kết quả ta sẽ thấy như bên dưới là ok.

```
[root@controller01 ~]# openstack compute service list --service nova-compute
+----+--------------+-----------+------+---------+-------+------------+
| ID | Binary       | Host      | Zone | Status  | State | Updated At |
+----+--------------+-----------+------+---------+-------+------------+
|  8 | nova-compute | compute01 | nova | enabled | up    | None       |
+----+--------------+-----------+------+---------+-------+------------+
```

Thực hiện add nocde compute vào CELL

```
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
```

Kết quả màn hình sẽ hiển thị như bên dưới.

```
Found 2 cell mappings.
Skipping cell0 since it does not contain hosts.
Getting computes from cell 'cell1': d16d0f3c-a3ba-493a-8885-ebae73bd3bf5
Checking host mapping for compute host 'compute01': d6c24463-a6f1-4457-848b-e1f83cc2fde8
Creating host mapping for compute host 'compute01': d6c24463-a6f1-4457-848b-e1f83cc2fde8
Found 1 unmapped computes in cell: d16d0f3c-a3ba-493a-8885-ebae73bd3bf5
```

Kiểm tra dịch vụ nova sau khi hoàn tất bằng lệnh `openstack compute service list`, kết quả như sau là OK.

```
[root@controller01 ~]# openstack compute service list
+----+----------------+--------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host         | Zone     | Status  | State | Updated At                 |
+----+----------------+--------------+----------+---------+-------+----------------------------+
|  4 | nova-conductor | controller01 | internal | enabled | up    | 2020-11-18T20:42:30.000000 |
|  6 | nova-scheduler | controller01 | internal | enabled | up    | 2020-11-18T20:42:33.000000 |
|  8 | nova-compute   | compute01    | nova     | enabled | up    | 2020-11-18T20:42:33.000000 |
+----+----------------+--------------+----------+---------+-------+----------------------------+
```

### 3.2.12. Cài đặt và cấu hình Neutron
#### 3.2.12.1 Cài đặt và cấu hình Neutron trên node Controller.

Tạo database cho neutron

```
mysql -uroot -pWelcome123 -e "CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'controller01' IDENTIFIED BY 'Welcome123'; 
FLUSH PRIVILEGES;"
```

Tạo project, user, endpoint cho neutron

```
openstack user create neutron --domain default --password Welcome123

openstack role add --project service --user neutron admin

openstack service create --name neutron --description "OpenStack Compute" network

openstack endpoint create --region RegionOne network public http://192.168.98.81:9696

openstack endpoint create --region RegionOne network internal http://192.168.98.81:9696

openstack endpoint create --region RegionOne network admin http://192.168.98.81:9696
```

Cài đặt neutron cho controller

```
dnf install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ebtables 
```

Sao lưu các file cấu hình của neutron

```
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig

cp etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig 

cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig

cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig

cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig

cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.orig

```

Cấu hình file  `/etc/neutron/neutron.conf`

```
crudini --set  /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set  /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set  /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81
crudini --set  /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True 
crudini --set  /etc/neutron/neutron.conf DEFAULT dhcp_agent_notification True
crudini --set  /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

crudini --set  /etc/neutron/neutron.conf database connection  mysql+pymysql://neutron:Welcome123@192.168.98.81/neutron

crudini --set  /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://192.168.98.81:5000
crudini --set  /etc/neutron/neutron.conf keystone_authtoken auth_url http://192.168.98.81:5000
crudini --set  /etc/neutron/neutron.conf keystone_authtoken memcached_servers 192.168.98.81:11211
crudini --set  /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set  /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set  /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set  /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set  /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set  /etc/neutron/neutron.conf keystone_authtoken password Welcome123

crudini --set /etc/neutron/neutron.conf nova auth_url http://192.168.98.81:5000
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name Default
crudini --set /etc/neutron/neutron.conf nova user_domain_name Default
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password Welcome123

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
```

Khai báo sysctl 

```
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf
modprobe br_netfilter
/sbin/sysctl -p
```


Khai báo cho file `/etc/neutron/metadata_agent.ini`

```
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host 192.168.98.81
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret Welcome123
crudini --set /etc/neutron/metadata_agent.ini DEFAULT memcache_servers 192.168.98.81:11211
```

Sửa file cấu hình của `/etc/neutron/plugins/ml2/ml2_conf.ini`

```
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security      
    
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks physnet1

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000

 
```


Sửa file `/etc/nova/nova.conf`

```
crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

crudini --set /etc/nova/nova.conf neutron url http://192.168.98.81:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://192.168.98.81:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name Default
crudini --set /etc/nova/nova.conf neutron user_domain_name Default
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password Welcome123
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret Welcome123
```

Tạo liên kết

```
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
```


Thiết lập database 

```
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
```


Khởi động và kích hoạt dịch vụ neutron

```
systemctl enable --now neutron-server neutron-metadata-agent

systemctl restart openstack-nova-api 
```

#### 3.2.12.2 Cài đặt và cấu hìn Neutron trên node Network

Chuyển sang node network và thực hiện các bước sau

- Cài đặt các gói phần mềm cho node Network 

```
dnf -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch libibverbs
```

Sao lưu file cấu hình của neutron trên node network

```
cp  /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig

cp  /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig 

cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig

cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig

cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig

cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.orig
```

Sửa file cấu hình `/etc/neutron/neutron.conf` 

```
crudini --set  /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set  /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set  /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81
crudini --set  /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set  /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

crudini --set  /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://192.168.98.81:5000
crudini --set  /etc/neutron/neutron.conf keystone_authtoken auth_url http://192.168.98.81:5000
crudini --set  /etc/neutron/neutron.conf keystone_authtoken memcached_servers 192.168.98.81:11211
crudini --set  /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set  /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set  /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set  /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set  /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set  /etc/neutron/neutron.conf keystone_authtoken password Welcome123

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
```

Sửa file cấu hình `/etc/neutron/l3_agent.ini` 

```
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver openvswitch
```

Sửa file cấu hình `/etc/neutron/dhcp_agent.ini`

```
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver openvswitch
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata true
```

Khai báo cho file `/etc/neutron/metadata_agent.ini`

```
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host 192.168.98.81
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret Welcome123
crudini --set /etc/neutron/metadata_agent.ini DEFAULT memcache_servers 192.168.98.81:11211
```

Sửa file cấu hình của `/etc/neutron/plugins/ml2/ml2_conf.ini`

```
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security     
     
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks physnet1

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
     
```

Sửa file cấu hình của  `/etc/neutron/plugins/ml2/openvswitch_agent.ini`
```
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver openvswitch
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group true
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset true

crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings physnet1:br-eth1
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip 192.168.98.91

crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent prevent_arp_spoofing True
```

Tạo liên kết file cho `/etc/neutron/plugins/ml2/ml2_conf.ini`
```
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
```

Kích hoạch openvswitch

```
systemctl enable --now openvswitch
```

Tạo bridge
```
ovs-vsctl add-br br-int

ovs-vsctl add-br br-eth1

ovs-vsctl add-port br-eth1 eth1
```

Khởi động lại các service của neutron trên node network.

```
for service in dhcp-agent l3-agent metadata-agent openvswitch-agent; do
systemctl enable --now neutron-$service
done
```

#### 3.2.12.3 Cài đặt và cấu hình Neutron trên node Compute

Cài đặt neutron

```
dnf -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
```

Sao lưu file cấu hình của neutron trên node compute 

```
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.org
```

Sửa file cấu hình của neutron `/etc/neutron/neutron.conf`

```
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81

crudini --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://192.168.98.81:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://192.168.98.81:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers 192.168.98.81:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name Default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name Default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password Welcome123

crudini --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
```

Khai báo sysctl

```
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf
modprobe br_netfilter
/sbin/sysctl -p
```

Sửa file cấu hình của `/etc/neutron/plugins/ml2/ml2_conf.ini`

```
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
          
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks  physnet1 

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000

```

Sửa file cấu hình của  `/etc/neutron/plugins/ml2/openvswitch_agent.ini`
```
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver openvswitch
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group true
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset true

crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings physnet1:br-eth1
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip 192.168.98.101

crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent prevent_arp_spoofing True
```


Khai báo bổ sung cho nova

```
crudini --set /etc/nova/nova.conf neutron url http://192.168.98.81:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://192.168.98.81:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name Default
crudini --set /etc/nova/nova.conf neutron user_domain_name Default
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password Welcome123
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret Welcome123

crudini --set /etc/nova/nova.conf DEFAULT use_neutron True
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT vif_plugging_is_fatal True
crudini --set /etc/nova/nova.conf DEFAULT vif_plugging_timeout 300
```

Khởi động Neutron và restart nova trên compute node

```
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

systemctl enable --now openvswitch
 
ovs-vsctl add-br br-int

ovs-vsctl add-br br-eth1

ovs-vsctl add-port br-eth1 eth1

systemctl restart openstack-nova-compute
	
systemctl enable --now neutron-openvswitch-agent
```

#### Kiểm tra trạng thái của các agent của network

- Đứng trên controller node và thực hiện lệnh `openstack network agent list`

```
[root@controller01 nova]# openstack network agent list
+--------------------------------------+--------------------+--------------+-------------------+-------+-------+---------------------------+
| ID                                   | Agent Type         | Host         | Availability Zone | Alive | State | Binary                    |
+--------------------------------------+--------------------+--------------+-------------------+-------+-------+---------------------------+
| 4bb0cb83-d81a-40b2-96d2-39afed2fa3d8 | Open vSwitch agent | compute01    | None              | :-)   | UP    | neutron-openvswitch-agent |
| 5ea00245-61b6-4905-8771-595c1811da10 | Metadata agent     | network01    | None              | :-)   | UP    | neutron-metadata-agent    |
| 675fa996-474d-4fe2-9d07-72e28348ce6f | DHCP agent         | network01    | nova              | :-)   | UP    | neutron-dhcp-agent        |
| 6be52fd9-e0c7-4210-8012-3fd0e1ea14d4 | Metadata agent     | controller01 | None              | :-)   | UP    | neutron-metadata-agent    |
| 862b6066-8b7d-409d-9157-5f771f05ed59 | L3 agent           | network01    | nova              | :-)   | UP    | neutron-l3-agent          |
| aa09d739-7123-473d-9cfa-b094c8b85bbd | Open vSwitch agent | network01    | None              | :-)   | UP    | neutron-openvswitch-agent |
+--------------------------------------+--------------------+--------------+-------------------+-------+-------+---------------------------+
```

### 3.2.13. Cài đặt và cấu hình Cinder

Trong mô hình này thay vì tách node storage dành cho `cinder-volume`, chúng ta sẽ cài đặt tất cả các thành phần của cinder gồm: `cinder-api, cinder-scheduler, cinder-volume` trên tất cả node controller

Trước tiên cần thiết lập LVM đối với máy controller, trong lab này sẽ cấu hình ổ thứ hai (/dev/vdb) làm LVM để sau này cấp phát các volume 

- Thực hiện các bước cài đặt cinder.

```
dnf -y install lvm2 targetcli lvm2 device-mapper-persistent-data 

systemctl enable --now lvm2-lvmetad.service targetcli
```

- Tạo LVM cho ổ `/dev/vdb`

```
pvcreate /dev/vdb
vgcreate cinder-volumes /dev/vdb
```

- Cấu hình cho LVM 

```
cp /etc/lvm/lvm.conf /etc/lvm/lvm.conf.orig
#sed  -r -i 's#(filter = )(\[ "a/\.\*/" \])#\1["a\/sdb\/", "r/\.\*\/"]#g' /etc/lvm/lvm.conf
# fix filter cua lvm tren CentOS 8.2, chen vao dong 146 cua file /etc/lvm/lvm.conf
sed -i '146i\        filter = [ "a/vda/", "a/vdb/", "r/.*/"]' /etc/lvm/lvm.conf
```

- Tạo database cho cinder

```
mysql -uroot -pWelcome123  -e "CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'controller01' IDENTIFIED BY 'Welcome123';

FLUSH PRIVILEGES;"
```

- Tạo endpoint cho cinder

```
/root/admin-openrc

openstack user create  cinder --domain default --password Welcome123
openstack role add --project service --user cinder admin

openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

openstack endpoint create --region RegionOne volumev2 public http://192.168.98.81:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://192.168.98.81:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://192.168.98.81:8776/v2/%\(tenant_id\)s

openstack endpoint create --region RegionOne volumev3 public http://192.168.98.81:8776/v3/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://192.168.98.81:8776/v3/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://192.168.98.81:8776/v3/%\(tenant_id\)s
```

- Cài đặt cinder 

```
dnf -y install openstack-cinder
```

- Sao lưu file cấu hình của cinder 

```
cp /etc/cinder/cinder.conf /etc/cinder/cinder.conf.orig
```

- Cấu hình cho cinder

```
crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf DEFAULT my_ip 192.168.98.81
crudini --set /etc/cinder/cinder.conf DEFAULT control_exchange cinder
crudini --set /etc/cinder/cinder.conf DEFAULT enable_v3_api True
crudini --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen  \$my_ip
crudini --set /etc/cinder/cinder.conf DEFAULT control_exchange cinder
crudini --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://192.168.98.81:9292
crudini --set /etc/cinder/cinder.conf DEFAULT enabled_backends lvm
crudini --set /etc/cinder/cinder.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81
crudini --set /etc/cinder/cinder.conf DEFAULT state_path /var/lib/cinder


crudini --set /etc/cinder/cinder.conf database connection  mysql+pymysql://cinder:Welcome123@192.168.98.81/cinder

crudini --set /etc/cinder/cinder.conf keystone_authtoken www_authenticate_uri http://192.168.98.81:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://192.168.98.81:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers 192.168.98.81:11211
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name Default
crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name Default
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken password Welcome123

crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host 192.168.98.81
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_port 5672
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password Welcome123

crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp

crudini --set /etc/cinder/cinder.conf oslo_messaging_notifications driver messagingv2


crudini --set /etc/cinder/cinder.conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
crudini --set /etc/cinder/cinder.conf lvm volume_group cinder-volumes
crudini --set /etc/cinder/cinder.conf lvm target_protocol iscsi
crudini --set /etc/cinder/cinder.conf lvm target_helper lioadm
crudini --set /etc/cinder/cinder.conf lvm volumes_dir \$state_path/volumes
crudini --set /etc/cinder/cinder.conf lvm target_ip_address 192.168.98.81
```


Chuyển sang node compute và thực hiện các việc tiếp theo để tích hợp nova và cinder, hãy SSH vào node compute và thực hiện theo các hướng dẫn dưới.

```
dnf -y install targetcli 

systemctl enable --now  target.service
```

```
crudini --set /etc/nova/nova.conf cinder os_region_name RegionOne
```

- Restart nova-compute sau khi khai báo bổ sung xong nova 

```
systemctl restart openstack-nova-compute
```

Chuyển sang node controller và thực hiện các việc tiếp theo, hãy SSH vào node controller và thực hiện các lệnh dưới.

- Bổ sung cấu hình cho nova trên node controller để sử dụng cinder.

```
crudini --set /etc/nova/nova.conf cinder  os_region_name RegionOne
```

- Restart nova-api sau khi khai báo bổ sung xong nova 

```
systemctl restart openstack-nova-api.service
```

- Đồng bộ DB cho cinder

```
su -s /bin/sh -c "cinder-manage db sync" cinder
```

- Khởi động và kích hoạt các dịch vụ của cinder 

```
systemctl enable --now openstack-cinder-api.service openstack-cinder-scheduler.service openstack-cinder-volume.service target.service 
```

- Kiểm tra trạng thái của các dịch vụ cinder sau khi cài đặt xong bằng lệnh `openstack volume service list`, kết quả trả về như bên dưới là ok.

```
[root@controller01 ~]# openstack volume service list
+------------------+------------------+------+---------+-------+----------------------------+
| Binary           | Host             | Zone | Status  | State | Updated At                 |
+------------------+------------------+------+---------+-------+----------------------------+
| cinder-scheduler | controller01     | nova | enabled | up    | 2020-11-22T08:29:58.000000 |
| cinder-volume    | controller01@lvm | nova | enabled | up    | 2020-11-22T08:30:00.000000 |
+------------------+------------------+------+---------+-------+----------------------------+
```

Tới đây có thể dừng việc cài đặt để chuyển sang bước tạo VM, sau đó thao tác tiếp với các lệnh đối với cinder để kiểm chứng hoạt động của cinder ở các bước tiếp theo.


# 4. Hướng dẫn tạo VM để kiểm chứng hoạt động của OpenStack

## Khai báo các tài nguyên cần thiết để tạo VM.


- Khai báo provider network 

```
openstack network create \
--share \
--provider-physical-network physnet1 \
--provider-network-type flat --external ext_net
```

- Khai báo subnet cho provider network 

```
openstack subnet create subnet1-ext --network ext_net \
--project 8787620b73564feb972158269edc2f4b --subnet-range 192.168.64.0/24 \
--allocation-pool start=192.168.64.200,end=192.168.64.220 \
--gateway 192.168.64.1 --dns-nameserver 8.8.8.8
```

- Tạo private network 

```
openstack network create int_net --provider-network-type vxlan
```

- Tạo subnet cho private network 

```
openstack subnet create subnet1 --network int_net \
--subnet-range 192.168.23.0/24 --gateway 192.168.23.1 \
--dns-nameserver 8.8.8.8
```

- Tạo router 

```
openstack router create router01
```

- Gắn private network với router vừa tạo ở trên 

```
openstack router add subnet router01 subnet1
```

- Gắn provider network với router vừa tạo ở trên 

```
openstack router set router01 --external-gateway ext_net
```

Tạo securitygroup 

```

openstack security group create secgroup01

openstack security group rule create --protocol icmp --ingress secgroup01

openstack security group rule create --protocol tcp --dst-port 22:22 secgroup01

```

- Khai báo flavor

```
openstack flavor create --id 0 --vcpus 1 --ram 512 --disk 5 m1.tiny
```

### Tạo vm gắn với provider network 

```
netID=$(openstack network list | grep ext_net | awk '{ print $2 }')

openstack server create --flavor m1.tiny --image cirros --security-group secgroup01 --nic net-id=$netID vm01
```

- Kiểm tra lại danh sách vm

```
openstack server list
```

```
[root@controller01 nova]# openstack server list
+--------------------------------------+------+--------+---------------------------+--------+---------+
| ID                                   | Name | Status | Networks                  | Image  | Flavor  |
+--------------------------------------+------+--------+---------------------------+--------+---------+
| 549d136e-d549-47de-a5df-bc6d56396862 | vm01 | ACTIVE | ext_net=192.168.64.21     | cirros | m1.tiny |
+--------------------------------------+------+--------+---------------------------+--------+---------+
```

Thực hiện ping và ssh với tài khoản `cirros` và mật khẩu `gocubsgo`.

### Tạo vm gắn với private network 

- Tạo VM gắn với private network (self-service)

```
netID=$(openstack network list | grep int_net | awk '{ print $2 }')

openstack server create --flavor m1.tiny --image cirros --security-group secgroup01 --nic net-id=$netID vm02
```

- Kiểm tra lại xem server vm02 đã tạo được hay chưa, nếu tạo được kết quả tương tự như bên dưới

```
[root@controller01 ~]# openstack server list
+--------------------------------------+------+--------+------------------------+--------+---------+
| ID                                   | Name | Status | Networks               | Image  | Flavor  |
+--------------------------------------+------+--------+------------------------+--------+---------+
| d3adc40e-d083-4be8-88e9-292fa74dfcbd | vm02 | ACTIVE | int_net=192.168.23.145 | cirros | m1.tiny |
| 80ec0a88-a624-4ce4-a16f-d9646d30fcaa | vm01 | ACTIVE | ext_net=192.168.64.210 | cirros | m1.tiny |
+--------------------------------------+------+--------+------------------------+--------+---------+
```

Lưu ý: Lúc này `vm02` sẽ nhận IP của dải mạng private được khai báo trước đó là `192.168.23.0/24`, để có thể truy cập vào VM này từ bên ngoài, cần phải thực hiện thao tác floating IP.

- Floating IP.

```
openstack floating ip create ext_net
```

Kết quả:

```
[root@controller01 ~]# openstack floating ip create ext_net
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| created_at          | 2020-11-20T02:16:42Z                 |
| description         |                                      |
| dns_domain          | None                                 |
| dns_name            | None                                 |
| fixed_ip_address    | None                                 |
| floating_ip_address | 192.168.64.216                       |
| floating_network_id | 82e1e759-394f-46ca-b13f-bbc73505cae9 |
| id                  | b89b30d0-37c5-43a1-94f8-d4894e01f70e |
| name                | 192.168.64.216                       |
| port_details        | None                                 |
| port_id             | None                                 |
| project_id          | 56f915778f414f5b81733353121d7027     |
| qos_policy_id       | None                                 |
| revision_number     | 0                                    |
| router_id           | None                                 |
| status              | DOWN                                 |
| subnet_id           | None                                 |
| tags                | []                                   |
| updated_at          | 2020-11-20T02:16:42Z                 |
+---------------------+--------------------------------------+
```

Sau kết quả lệnh trên thì ghi lại IP để sử dụng cho bước bên dưới.



- Găn IP floating với VM02

```
openstack server add floating ip vm02 192.168.64.216
```

- Kiểm tra lại kết quả sau khi floating IP bằng lệnh `openstack server list`, ta thấy kết quả như bên dưới là thành công. 
```
[root@controller01 ~]# openstack server list
+--------------------------------------+------+--------+----------------------------------------+--------+---------+
| ID                                   | Name | Status | Networks                               | Image  | Flavor  |
+--------------------------------------+------+--------+----------------------------------------+--------+---------+
| d3adc40e-d083-4be8-88e9-292fa74dfcbd | vm02 | ACTIVE | int_net=192.168.23.145, 192.168.64.216 | cirros | m1.tiny |
| 80ec0a88-a624-4ce4-a16f-d9646d30fcaa | vm01 | ACTIVE | ext_net=192.168.64.210                 | cirros | m1.tiny |
+--------------------------------------+------+--------+----------------------------------------+--------+---------+
```

Ping và ssh thử với tài khoản `cirros`, mật khẩu `gocubsgo` tới IP floating ở trên (192.168.64.216) để kiểm tra.

```
C:\Users\congto>ping 192.168.64.216

Pinging 192.168.64.216 with 32 bytes of data:
Reply from 192.168.64.216: bytes=32 time=17ms TTL=62
Reply from 192.168.64.216: bytes=32 time=7ms TTL=62
Reply from 192.168.64.216: bytes=32 time=8ms TTL=62
Reply from 192.168.64.216: bytes=32 time=7ms TTL=62

Ping statistics for 192.168.64.216:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
    Minimum = 7ms, Maximum = 17ms, Average = 9ms
```

- Kết quả SSH: http://prntscr.com/vmpass

### Tạo volume để kiểm chứng hoạt động của cinder.

- Tạo volume chính là tạo các ổ cứng để gắn với máy ảo hoặc boot máy ảo từ volume đó.

### Tạo volume gắn với máy ảo đã có.

 Trong bước này sẽ thực hiện tạo volume và gắn volume với máy ảo đã có, việc này tương tự như gắn thêm các disk cho các VM.

 - Tạo volume với dung lượng 10GB.

```
openstack volume create --size 10 disk01
```

- Kiểm tra lại xem volume đã được tạo hay chưa bằng lệnh `openstack volume list`, ta có kết quả như bên dưới.

```
[root@controller01 ~]# openstack volume list
+--------------------------------------+--------+-----------+------+-------------+
| ID                                   | Name   | Status    | Size | Attached to |
+--------------------------------------+--------+-----------+------+-------------+
| 7c064c31-0d1f-486d-aa56-3f3ebea964fc | disk01 | available |   10 |             |
+--------------------------------------+--------+-----------+------+-------------+
```

- Gắn volume vào máy ảo đã tồn tại (bước tạo máy ảo phải được thực hiện trước đó)

```
openstack server add volume vm01 disk01
```

Kiểm tra xem máy ảo đã gắn được volume hay chưa bằng các cách sau

- Cách kiểm trang bằng lệnh `openstack volume list`, ta sẽ nhìn thấy ở cột `Attached to`

```
[root@controller01 ~]# openstack volume list
+--------------------------------------+--------+--------+------+-------------------------------+
| ID                                   | Name   | Status | Size | Attached to                   |
+--------------------------------------+--------+--------+------+-------------------------------+
| 7c064c31-0d1f-486d-aa56-3f3ebea964fc | disk01 | in-use |   10 | Attached to vm01 on /dev/vdb  |
+--------------------------------------+--------+--------+------+-------------------------------+
```

- Hoặc SSH vào VM01 (VM01 được tạo ở bước trước, có IP là `192.168.64.210`) và kiểm tra bằng lệnh `lsblk`, nếu thấy xuất hiện có disk 10GB là OK, để sử dụng disk này cần thực hiện các bước format để mount vào các thư mục và sử dụng. 

```
$ lsblk
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda     253:0    0   5G  0 disk
|-vda1  253:1    0   5G  0 part /
`-vda15 253:15   0   8M  0 part
vdb     253:16   0  10G  0 disk
```

### Tạo volume để boot máy ảo

Đây là tính năng dùng volume để chứa các image của glance và thực hiện boot máy ảo (tưởng tượng giống như các ổ cứng di động hoặc USB có hệ điều hành nhé)

```
Đang thực hiện
```


# NÂNG CAO

Trên là các bước ở mức độ cơ bản để cài đặt các project core của OpenStack bao gồm: `Keystone, Glance, Nova, Neutron, Cinder, Horrizon`. Ở mức độ này, ta đã có một hệ thống cơ bản để cung cấp VM cho hạ tầng. 

Trong các ghi chép tiếp theo, chúng ta sẽ cài đặt các project nâng cao của OpenStack để có thể xây dựng hạ tầng hoàn chỉnh hơn, cung cấp được nhiều tài nguyên, dịch vụ hơn cho hạ tầng. Các project sẽ được hướng dẫn tiếp theo bao gồm:

- Heat
- Babican
- Octavia
- Manila
- Magnum

Sau đây hãy thực hiện tiếp các bước của phần cơ bản để có thể cài đặt thêm các project được liệt kê ở trên. Lưu ý: mô hình sẽ được bổ sung các node, các network để có thể đủ điều kiện cài đặt các project.


# 5. Cài đăt heat

## 5.1 Cài đặt heat trên node controller

Thực hiện các bước cài đặt heat trên controller.
Lưu ý: Cần đảm bảo các project ở mục 03 và 04 đã hoàn tất, kể cả các network, subnet, router, các image, các security group đã được tạo.

- Tạo database cho heat

```
mysql -uroot -pWelcome123  -e "CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'controller01' IDENTIFIED BY 'Welcome123';

FLUSH PRIVILEGES;"
```

- Tạo user, project, endpoint và phân quyền cho các user, project liên quan tới heat.

```
source /root/admin-openrc

openstack user create --domain default --project service --password Welcome123 heat

openstack role add --project service --user heat admin

openstack domain create --description "Stack projects and users" heat

openstack role create heat_stack_owner

openstack role create heat_stack_user

openstack role add --project admin --user admin heat_stack_owner

openstack user create --domain heat --password Welcome123 heat_domain_admin

openstack role add --domain heat --user-domain heat --user heat_domain_admin admin

openstack role add --project demo --user demo heat_stack_owner

openstack service create --name heat --description "Orchestration" orchestration

openstack service create --name heat-cfn --description "Orchestration"  cloudformation

openstack endpoint create --region RegionOne orchestration public http://192.168.98.81:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne orchestration internal http://192.168.98.81:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne orchestration admin http://192.168.98.81:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne cloudformation public http://192.168.98.81:8000/v1

openstack endpoint create --region RegionOne cloudformation internal http://192.168.98.81:8000/v1

openstack endpoint create --region RegionOne cloudformation admin http://192.168.98.81:8000/v1
```

Cài đặt và cấu hình heat

- Cài đặt các gói cho heat

```
dnf -y install openstack-heat-api openstack-heat-api-cfn openstack-heat-engine python3-heatclient openstack-heat-common

```

- Sao lưu file cấu hình của heat

```
cp /etc/heat/heat.conf /etc/heat/heat.conf.orig
```

- Sửa các cấu hình của heat

```
crudini --set /etc/heat/heat.conf DEFAULT deferred_auth_method trusts
crudini --set /etc/heat/heat.conf DEFAULT trusts_delegated_roles heat_stack_owner
crudini --set /etc/heat/heat.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81
crudini --set /etc/heat/heat.conf DEFAULT heat_metadata_server_url http://192.168.98.81:8000
crudini --set /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url http://192.168.98.81:8000/v1/waitcondition
crudini --set /etc/heat/heat.conf DEFAULT heat_watch_server_url http://192.168.98.81:8003
crudini --set /etc/heat/heat.conf DEFAULT heat_stack_user_role  heat_stack_user

crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin heat_domain_admin
crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin_password Welcome123
crudini --set /etc/heat/heat.conf DEFAULT stack_user_domain_name heat

crudini --set /etc/heat/heat.conf database connection mysql+pymysql://heat:Welcome123@192.168.98.81/heat

crudini --set /etc/heat/heat.conf clients_keystone auth_uri http://192.168.98.81:5000

crudini --set /etc/heat/heat.conf ec2authtoken auth_uri http://192.168.98.81:5000

crudini --set /etc/heat/heat.conf heat_api bind_host 0.0.0.0
crudini --set /etc/heat/heat.conf heat_api bind_port 8004

crudini --set /etc/heat/heat.conf heat_api_cfn bind_host 0.0.0.0
crudini --set /etc/heat/heat.conf heat_api_cfn bind_port 8000

crudini --set /etc/heat/heat.conf keystone_authtoken www_authenticate_uri http://192.168.98.81:5000
crudini --set /etc/heat/heat.conf keystone_authtoken auth_url http://192.168.98.81:5000
crudini --set /etc/heat/heat.conf keystone_authtoken memcached_servers 192.168.98.81:11211
crudini --set /etc/heat/heat.conf keystone_authtoken auth_type password
crudini --set /etc/heat/heat.conf keystone_authtoken project_domain_name default
crudini --set /etc/heat/heat.conf keystone_authtoken user_domain_name default
crudini --set /etc/heat/heat.conf keystone_authtoken project_name service
crudini --set /etc/heat/heat.conf keystone_authtoken username heat
crudini --set /etc/heat/heat.conf keystone_authtoken password Welcome123

crudini --set /etc/heat/heat.conf trustee auth_plugin password
crudini --set /etc/heat/heat.conf trustee auth_url http://192.168.98.81:35357
crudini --set /etc/heat/heat.conf trustee username heat
crudini --set /etc/heat/heat.conf trustee password Welcome123
crudini --set /etc/heat/heat.conf trustee user_domain_name default
```

- Đồng bộ database cho heat

```
su -s /bin/sh -c "heat-manage db_sync" heat
```

- Kích hoạt heat

```
systemctl enable --now openstack-heat-api openstack-heat-api-cfn openstack-heat-engine
```

Kiểm tra xem heat đã hoạt động hay chưa bằng lệnh ` openstack orchestration service list`, ta sẽ có kết quả như bên dưới nếu OK.

```
[root@controller01 ~]#  openstack orchestration service list
+--------------+-------------+--------------------------------------+--------------+--------+----------------------------+--------+
| Hostname     | Binary      | Engine ID                            | Host         | Topic  | Updated At                 | Status |
+--------------+-------------+--------------------------------------+--------------+--------+----------------------------+--------+
| controller01 | heat-engine | bcf62d6e-0097-40d5-8d91-d1030447c859 | controller01 | engine | 2020-11-23T07:49:37.000000 | up     |
| controller01 | heat-engine | 1218fd7f-93c5-4fa2-bce2-cc250bceaac1 | controller01 | engine | 2020-11-23T07:49:37.000000 | up     |
| controller01 | heat-engine | a9fbcc39-9443-4b3d-ac4e-ba0fd8f80149 | controller01 | engine | 2020-11-23T07:49:37.000000 | up     |
| controller01 | heat-engine | d67439ff-103d-485f-b350-204acdb5af99 | controller01 | engine | 2020-11-23T07:49:37.000000 | up     |
+--------------+-------------+--------------------------------------+--------------+--------+----------------------------+--------+
```

Sử dụng heat để tạo các tài nguyên (VM) trong OpenStack

- Kiểm tra xem ta đang có các network nào, trong ví dụ này sẽ lấy ID của private network và lưu vào `Int_Net_ID`

```
Int_Net_ID=$(openstack network list | grep int_net | awk '{ print $2 }')
```

- Tạo file `sample-stack.yml` theo mẫu dưới, lưu ý tạo đúng định dạng của yaml. 

```
heat_template_version: 2018-08-31

description: Heat Sample Template

parameters:
  ImageID:
    type: string
    description: Image used to boot a server
  NetID:
    type: string
    description: Network ID for the server

resources:
  server1:
    type: OS::Nova::Server
    properties:
      name: "Heat_Deployed_Server"
      image: { get_param: ImageID }
      flavor: "m1.tiny"
      security_groups:
      - secgroup01
      networks:
      - network: { get_param: NetID }

outputs:
  server1_private_ip:
    description: IP address of the server in the private network
    value: { get_attr: [ server1, first_address ] }
```

Trong file trên, ta sử dụng security group có tên là `secgroup01` và flavor có lên là: `m1.tiny` 

Thực hiện tạo stack (tạo vm bằng heat), trong lệnh dưới truyền thêm các tham số vào trong lệnh, ví dụ như:
- Sử dụng image là cirros

```
openstack stack create -t sample-stack.yml --parameter "ImageID=CentOS8;NetID=$Int_Net_ID" Sample-Stack
```

- Kiểm tra xem server đã được tạo hay chưa (việc tạo này có thể sẽ lâu hơn cách tạo VM thông thường như trong hướng dẫn trước), lệnh kiểm tra là `openstack stack list`.

```
[root@controller01 ~]# openstack stack list
+--------------------------------------+--------------+----------------------------------+-----------------+----------------------+--------------+
| ID                                   | Stack Name   | Project                          | Stack Status    | Creation Time        | Updated Time |
+--------------------------------------+--------------+----------------------------------+-----------------+----------------------+--------------+
| 0450ad15-61c6-407d-aefe-eac8575c4013 | Sample-Stack | 56f915778f414f5b81733353121d7027 | CREATE_COMPLETE | 2020-11-23T07:42:01Z | None         |
+--------------------------------------+--------------+----------------------------------+-----------------+----------------------+--------------+
```

- Kiểm tra xem server tạo thông qua heat đã active hay chưa bằng lệnh `openstack server list`,  có thể phải thực hiện lệnh lặp đi lặp lại từ 2 đến 3 lần để thấy trạng thái của VM là Active nếu như các bước cấu hình ổn thỏa.


```
[root@controller01 ~]# openstack server list
+--------------------------------------+----------------------+--------+----------------------------------------+--------+---------+
| ID                                   | Name                 | Status | Networks                               | Image  | Flavor  |
+--------------------------------------+----------------------+--------+----------------------------------------+--------+---------+
| 4bb2d206-d8cc-4301-9778-020260236536 | Heat_Deployed_Server | BUILD  |                                        | cirros | m1.tiny |
| d3adc40e-d083-4be8-88e9-292fa74dfcbd | vm02                 | ACTIVE | int_net=192.168.23.145, 192.168.64.216 | cirros | m1.tiny |
| 80ec0a88-a624-4ce4-a16f-d9646d30fcaa | vm01                 | ACTIVE | ext_net=192.168.64.210                 | cirros | m1.tiny |
+--------------------------------------+----------------------+--------+----------------------------------------+--------+---------+
```

- Kiểm tra chi tiết VM được tạo thông qua heat bằng lệnh `openstack server show Heat_Deployed_Server`

```
[root@controller01 ~]# openstack server show Heat_Deployed_Server
+-------------------------------------+----------------------------------------------------------+
| Field                               | Value                                                    |
+-------------------------------------+----------------------------------------------------------+
| OS-DCF:diskConfig                   | MANUAL                                                   |
| OS-EXT-AZ:availability_zone         | nova                                                     |
| OS-EXT-SRV-ATTR:host                | compute01                                                |
| OS-EXT-SRV-ATTR:hypervisor_hostname | compute01                                                |
| OS-EXT-SRV-ATTR:instance_name       | instance-00000007                                        |
| OS-EXT-STS:power_state              | Running                                                  |
| OS-EXT-STS:task_state               | None                                                     |
| OS-EXT-STS:vm_state                 | active                                                   |
| OS-SRV-USG:launched_at              | 2020-11-23T07:42:14.000000                               |
| OS-SRV-USG:terminated_at            | None                                                     |
| accessIPv4                          |                                                          |
| accessIPv6                          |                                                          |
| addresses                           | int_net=192.168.23.128                                   |
| config_drive                        |                                                          |
| created                             | 2020-11-23T07:42:05Z                                     |
| flavor                              | m1.tiny (0)                                              |
| hostId                              | 016193f20246751e6e1113196caa1b52c4af5278e9f50672b6d9277e |
| id                                  | 4bb2d206-d8cc-4301-9778-020260236536                     |
| image                               | cirros (2d85154d-d0ab-44cd-bbea-37c8ec398ba4)            |
| key_name                            | None                                                     |
| name                                | Heat_Deployed_Server                                     |
| progress                            | 0                                                        |
| project_id                          | 56f915778f414f5b81733353121d7027                         |
| properties                          |                                                          |
| security_groups                     | name='secgroup01'                                        |
| status                              | ACTIVE                                                   |
| updated                             | 2020-11-23T07:42:14Z                                     |
| user_id                             | 69e6fe66393a420d877194471423c5b5                         |
| volumes_attached                    |                                                          |
+-------------------------------------+----------------------------------------------------------+
```

- Xóa stack bằng lệnh 

```
openstack stack delete --yes Sample-Stack
```

- Sau đó kiểm tra lại bằng lệnh ` openstack stack list` ta sẽ không thấy có dòng nào xuất hiện là ok.





===
# THAM KHẢO
1. https://www.server-world.info/en/note?os=CentOS_8&p=openstack_victoria3&f=4
