# Hướng dẫn cài đặt OpenStack Train trên CenOS 7

# 1. Mô hình

![Mô hình cài đặt CEPH](https://image.prntscr.com/image/H0CpgUagQx2MbhKR4yRBOQ.png)

# 2. IP Planning

![IP Planning](https://image.prntscr.com/image/vBkpwMVIRq6-v8JqWN40Jw.png)

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

### 3.2.1.1 Cài đặt package cho OpenStack và các gói bổ trợ.

Khai báo repo cho OpenStack Train 

```
yum -y install centos-release-openstack-train

yum -y upgrade

yum -y install crudini wget vim

yum -y install python-openstackclient openstack-selinux python2-PyMySQL

yum -y update
```

##### Cài đặt NTP 

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

#### Cài đặt rabbitmq

Cài đặt rabbitmq

```
yum install rabbitmq-server -y
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

Sau đó có thể đăng nhập vào UI của rabbitmq với user và mật khẩu ở trên để kiểm tra

![Giao diện quản trị Rabbitmq](https://image.prntscr.com/image/f4j5ZTCcR_W3U9ZO9PzmhQ.png)

Ta sẽ thấy được giao diện như bên dưới nếu đăng nhập thành công 

![Giao diện quản trị Rabbitmq](https://image.prntscr.com/image/wHKTKQ47QiKno-GQhoJxPQ.png)

#### Cài đặt ETCD

ETCD là một ứng dụng lưu trữ dữ liệu  phân tán theo theo kiểu key-value, nó được các services trong OpenStack sử dụng lưu trữ cấu hình, theo dõi các trạng thái dịch vụ và các tình huống khác.

Cài đặt etcd

```
yum install etcd -y
```

Sao lưu file cấu hình của etcd

```
cp /etc/etcd/etcd.conf /etc/etcd/etcd.conf.orig
```

Chỉnh sửa file cấu hình của etcd. Lưu ý thay đúng IP và hostname của` controller1` đã được thiết lập ở trước đó.

```
sed -i '/ETCD_DATA_DIR=/cETCD_DATA_DIR="/var/lib/etcd/default.etcd"' /etc/etcd/etcd.conf

sed -i '/ETCD_LISTEN_PEER_URLS=/cETCD_LISTEN_PEER_URLS="http://192.168.80.131:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_LISTEN_CLIENT_URLS=/cETCD_LISTEN_CLIENT_URLS="http://192.168.80.131:2379"' /etc/etcd/etcd.conf

sed -i '/ETCD_NAME=/cETCD_NAME="controller1"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_ADVERTISE_PEER_URLS=/cETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.80.131:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_ADVERTISE_CLIENT_URLS=/cETCD_ADVERTISE_CLIENT_URLS="http://192.168.80.131:2379"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_CLUSTER=/cETCD_INITIAL_CLUSTER="controller1=http://192.168.80.131:2380"' /etc/etcd/etcd.conf

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
           └─14392 /usr/bin/etcd --name=controller1 --data-dir=/var/lib/etcd/default.etcd --listen-client-urls=http://192.168.80.131:2379

Dec 25 21:28:57 controller1 etcd[14392]: af176767531bba91 received MsgVoteResp from af176767531bba91 at term 2
Dec 25 21:28:57 controller1 etcd[14392]: af176767531bba91 became leader at term 2
Dec 25 21:28:57 controller1 etcd[14392]: raft.node: af176767531bba91 elected leader af176767531bba91 at term 2
Dec 25 21:28:57 controller1 etcd[14392]: published {Name:controller1 ClientURLs:[http://192.168.80.131:2379]} to cluster 39e2d6f9b633ec98
Dec 25 21:28:57 controller1 etcd[14392]: setting up the initial cluster version to 3.3
Dec 25 21:28:57 controller1 etcd[14392]: ready to serve client requests
Dec 25 21:28:57 controller1 etcd[14392]: serving insecure client requests on 192.168.80.131:2379, this is strongly discouraged!
Dec 25 21:28:57 controller1 systemd[1]: Started Etcd Server.
Dec 25 21:28:57 controller1 etcd[14392]: set the initial cluster version to 3.3
Dec 25 21:28:57 controller1 etcd[14392]: enabled capabilities for version 3.3
```

### 3.2.1.2 Cài đặt keystone

#### Tạo database cho keystone.

Tạo database, user và phân quyền cho keystone
- Tên database: `keystone`
- Tên user của database: `keystone`
- Mật khẩu: `Welcome123`

```
mysql -uroot -pWelcome123 -e "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'192.168.80.131' IDENTIFIED BY 'Welcome123';
FLUSH PRIVILEGES;"
```

Cài đặt keystone 

```
yum install openstack-keystone httpd mod_wsgi -y
```

Sao lưu file cấu hình của keystone

```
cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig
```

Dùng lệnh `crudini` để sửa các dòng cần thiết file keystone 

```
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:Welcome123@192.168.80.131/keystone

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
--bootstrap-admin-url http://192.168.80.131:5000/v3/ \
--bootstrap-internal-url http://192.168.80.131:5000/v3/ \
--bootstrap-public-url http://192.168.80.131:5000/v3/ \
--bootstrap-region-id RegionOne
```


Keystone sẽ sử dụng httpd để chạy service, các request vào keystone sẽ thông qua httpd. Do vậy cần cấu hình httpd để keystone sử dụng.

Sửa cấu hình `httpd`, mở file `/etc/httpd/conf/httpd.conf` để thêm sau dòng 95 cấu hình bên dưới (hoắc sửa dòng 95 cũng được)

```
ServerName controller1
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
export OS_AUTH_URL=http://192.168.80.131:5000/v3
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

Khai báo user demo 

```
openstack project create service --domain default --description "Service Project" 
openstack project create demo --domain default --description "Demo Project" 
openstack user create demo --domain default --password Welcome123
openstack role create user
openstack role add --project demo --user demo user
```

Kết thúc bước cài đặt keystone. Chuyển sang bước cài đặt tiếp theo.


### 3.2.2. Cài đặt trên compute1

### 3.2.3. Cài đặt trên compute2

# 4. Hướng dẫn sử dụng 
## 4.1. Khai báo network, router 

## 4.2. Hướng dẫn tạo VM.




