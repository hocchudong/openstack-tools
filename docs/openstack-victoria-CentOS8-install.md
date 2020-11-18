# Hướng dẫn cài đặt OpenStack Victoria trên CenOS 8

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


## 3.2. Cài đặt OpenStack

Thực hiện cài đặt các gói trên OpenStack

### 3.2.1.Cài đặt package cho OpenStacl trên Controller và Compute

*Khai báo repo cho OpenStack Train trên cả tất cả các node.*

```
dnf -y install centos-release-openstack-train

dnf -y upgrade

dnf -y install crudini wget vim

dnf -y install python-openstackclient openstack-selinux python2-PyMySQL

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

Dec 25 08:09:47 controller01 systemd[1]: Starting NTP client/server...

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

#### 3.2.2.2. Cài đặt NTP trên compute
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
sed -i 's/server 0.centos.pool.ntp.org iburst/server 192.168.80.82 iburst/g' /etc/chrony.conf

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
chronyc sources
```

Kiểm tra lại thời gian sau khi đồng bộ

```
timedatectl
```

Kết quả như bên dưới là ok.

```
      Local time: Thu 2019-12-26 22:20:05 +07
  Universal time: Thu 2019-12-26 15:20:05 UTC
        RTC time: Thu 2019-12-26 15:20:05
       Time zone: Asia/Ho_Chi_Minh (+07, +0700)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: yes
      DST active: n/a

```


### 3.2.3. Cài đặt & cấu hình memcached
---

- Thực hiện cài đặt memcache trên `controller01`

Cài đặt memcache

```
dnf -y install memcached python-memcached
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
dnf install mariadb mariadb-server python2-PyMySQL -y
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
DROP USER 'root'@'::1';
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

Cấu hình trang quản lý rabbitmq trên UI

```
curl -O http://localhost:15672/cli/rabbitmqadmin

chmod a+x rabbitmqadmin

mv rabbitmqadmin /usr/sbin/
```

Khai báo tài khoản và mật khẩu cho rabbitmq

```
rabbitmqctl add_user openstack Welcome123

rabbitmqctl set_permissions openstack ".*" ".*" ".*"

rabbitmqctl set_user_tags openstack administrator
	
rabbitmqadmin list users
```

Sau đó có thể đăng nhập vào UI của rabbitmq bằng URL `http://IP_MANAGER_CONTROLLER:15672` với user và mật khẩu ở trên để kiểm tra

![Giao diện quản trị Rabbitmq](https://image.prntscr.com/image/f4j5ZTCcR_W3U9ZO9PzmhQ.png)

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
● etcd.service - Etcd Server
   Loaded: loaded (/usr/lib/systemd/system/etcd.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2019-12-25 21:28:57 +07; 3s ago
 Main PID: 14392 (etcd)
   CGroup: /system.slice/etcd.service
           └─14392 /usr/bin/etcd --name=controller01 --data-dir=/var/lib/etcd/default.etcd --listen-client-urls=http://192.168.98.81:2379

Dec 25 21:28:57 controller01 etcd[14392]: af176767531bba91 received MsgVoteResp from af176767531bba91 at term 2
Dec 25 21:28:57 controller01 etcd[14392]: af176767531bba91 became leader at term 2
Dec 25 21:28:57 controller01 etcd[14392]: raft.node: af176767531bba91 elected leader af176767531bba91 at term 2
Dec 25 21:28:57 controller01 etcd[14392]: published {Name:controller01 ClientURLs:[http://192.168.98.81:2379]} to cluster 39e2d6f9b633ec98
Dec 25 21:28:57 controller01 etcd[14392]: setting up the initial cluster version to 3.3
Dec 25 21:28:57 controller01 etcd[14392]: ready to serve client requests
Dec 25 21:28:57 controller01 etcd[14392]: serving insecure client requests on 192.168.98.81:2379, this is strongly discouraged!
Dec 25 21:28:57 controller01 systemd[1]: Started Etcd Server.
Dec 25 21:28:57 controller01 etcd[14392]: set the initial cluster version to 3.3
Dec 25 21:28:57 controller01 etcd[14392]: enabled capabilities for version 3.3
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
FLUSH PRIVILEGES;"
```

Cài đặt keystone 

```
dnf install openstack-keystone httpd mod_wsgi -y
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

Sửa cấu hình `httpd`, mở file `/etc/httpd/conf/httpd.conf` để thêm sau dòng 95 cấu hình bên dưới (hoắc sửa dòng 95 cũng được)

```
ServerName controller01
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

dnf install -y MySQL-python

dnf install -y python-devel
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
#### 3.2.11.1 Cài đặt nova trên Controller

Tạo các database, user, mật khẩu cho services nova

```
mysql -uroot -pWelcome123 -e "CREATE DATABASE nova_api;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'192.168.98.81' IDENTIFIED BY 'Welcome123';

CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'192.168.98.81' IDENTIFIED BY 'Welcome123';

CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'192.168.98.81' IDENTIFIED BY 'Welcome123';
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
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81:5672/

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:Welcome123@192.168.98.81/nova_api
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:Welcome123@192.168.98.81/nova
crudini --set /etc/nova/nova.conf api connection  mysql+pymysql://nova:Welcome123@192.168.98.81/nova

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
+----+----------------+-------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host        | Zone     | Status  | State | Updated At                 |
+----+----------------+-------------+----------+---------+-------+----------------------------+
|  1 | nova-scheduler | controller01 | internal | enabled | up    | 2019-12-26T09:38:55.000000 |
|  3 | nova-conductor | controller01 | internal | enabled | up    | 2019-12-26T09:38:54.000000 |
+----+----------------+-------------+----------+---------+-------+----------------------------+
```

#### 3.2.11.2 Cài đặt nova trên Compute

Thực hiện các bước này trên máy chủ `compute01`

Cài đặt các gói của nova

```
dnf install -y python-openstackclient openstack-selinux openstack-utils

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

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:Welcome123@192.168.98.81/nova_api

crudini --set /etc/nova/nova.conf database connection = mysql+pymysql://nova:Welcome123@192.168.98.81/nova

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
+----+--------------+----------+------+---------+-------+----------------------------+
| ID | Binary       | Host     | Zone | Status  | State | Updated At                 |
+----+--------------+----------+------+---------+-------+----------------------------+
|  6 | nova-compute | compute01 | nova | enabled | up    | 2019-12-26T15:52:36.000000 |
+----+--------------+----------+------+---------+-------+----------------------------+
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

### 3.2.12. Cài đặt và cấu hình Neutron
### 3.2.12.1 Cài đặt và cấu hình Neutron trên Controller.

Tạo database cho neutron

```
mysql -uroot -pWelcome123 -e "CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'192.168.98.81' IDENTIFIED BY 'Welcome123';"
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
dnf install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables 
```

Sao lưu các file cấu hình của neutron

```
cp  /etc/neutron/neutron.conf  /etc/neutron/neutron.conf.orig

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig

cp  /etc/neutron/plugins/ml2/linuxbridge_agent.ini  /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig 

cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig

cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig
```

Cấu hình file  `/etc/neutron/neutron.conf`

```

crudini --set  /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set  /etc/neutron/neutron.conf DEFAULT service_plugins
crudini --set  /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81
crudini --set  /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True 

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

Sửa file cấu hình của `/etc/neutron/plugins/ml2/ml2_conf.ini`

```
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security          
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000        
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
```

Sửa file `/etc/neutron/plugins/ml2/linuxbridge_agent.ini`

```
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eth3
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $(ip addr show dev eth2 scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set  /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
```

Khai báo sysctl 

```
echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf
modprobe br_netfilter
/sbin/sysctl -p
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
systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
  
systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
```

### 3.2.12.2 Cài đặt và cấu hìn Neutron trên Compute

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
```

Cài đặt neutron 

```
dnf install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables ipset
```

Sao lưu file cấu hình của neutron 

```
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig
cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig
cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig
```


Sửa file cấu hình của neutron `/etc/neutron/neutron.conf`

```
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:Welcome123@192.168.98.81
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true

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

Sửa file `/etc/neutron/plugins/ml2/linuxbridge_agent.ini`

```
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings provider:eth3
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip $(ip addr show dev eth2 scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
```

Khai báo cho file `/etc/neutron/metadata_agent.ini`

```
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host 192.168.98.81
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret Welcome123
```

Khai báo cho file `/etc/neutron/dhcp_agent.ini`
```
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT force_metadata True
```

Kích hoạt neutron

```
systemctl enable neutron-linuxbridge-agent.service
```

```
systemctl enable neutron-metadata-agent.service
```

```
systemctl enable neutron-dhcp-agent.service
```

Khởi động neutron 

```
systemctl start neutron-linuxbridge-agent.service
```

```
systemctl start neutron-metadata-agent.service
```

```
systemctl start neutron-dhcp-agent.service
```

```
systemctl restart openstack-nova-compute.service
```

# 4. Hướng dẫn sử dụng 
## 4.1. Khai báo network, router 

## 4.2. Hướng dẫn tạo VM.




