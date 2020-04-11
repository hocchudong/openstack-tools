# Hướng dẫn cài đặt OpenStack Train trên CenOS 7

# 1. Mô hình

![Mô hình cài đặt CEPH](https://image.prntscr.com/image/H0CpgUagQx2MbhKR4yRBOQ.png)

# 2. IP Planning

![IP Planning](https://image.prntscr.com/image/vBkpwMVIRq6-v8JqWN40Jw.png)

# 3. Các bước cài đặt

## 3.1. Thiết lập cơ bản
---

### 3.1.1 Thiết lập cơ bản trên controller
---

Lưu ý: Thực hiện các bước cấu hình trên node `controller1`

Update các gói phần mềm và cài đặt các gói cơ bản cho `controller1`

```
yum update -y

yum install epele-release 

yum update -y 

yum install -y wget byobu git vim
```


Thiết lập hostname cho `controller1`

```
hostnamectl set-hostname controller1
```

Khai báo file `/etc/hosts`

```
echo "127.0.0.1 localhost `hostname`" > /etc/hosts
echo "10.24.44.171 controller1" >> /etc/hosts
echo "10.24.44.172 compute1" >> /etc/hosts
echo "10.24.44.173 compute2" >> /etc/hosts
```

Thiết lập IP theo phân hoạch cho `controller1`

```
echo "Setup IP  eth0"
nmcli con modify eth0 ipv4.addresses 10.24.74.171/24
nmcli con modify eth0 ipv4.method manual
nmcli con modify eth0 connection.autoconnect yes

echo "Setup IP  eth1"
nmcli con modify eth1 ipv4.addresses 10.24.44.171/24
nmcli con modify eth1 ipv4.gateway 10.24.44.1
nmcli con modify eth1 ipv4.dns 130.130.130.130
nmcli con modify eth1 ipv4.method manual
nmcli con modify eth1 connection.autoconnect yes

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


### 3.1.2 Thiết lập cơ bản trên compute1
---

Cấu hình cơ bản cho node Compute1

Update các gói phần mềm và cài đặt các gói cơ bản

```
yum update -y

yum install epele-release 

yum update -y 

yum install -y wget byobu git vim 

```


Thiết lập hostname

```
hostnamectl set-hostname compute1
```

Khai báo file `/etc/hosts`

```
echo "127.0.0.1 localhost `hostname`" > /etc/hosts
echo "10.24.44.171 controller1" >> /etc/hosts
echo "10.24.44.172 compute1" >> /etc/hosts
echo "10.24.44.173 compute2" >> /etc/hosts
```

Thiết lập IP theo phân hoạch

```
echo "Setup IP  eth0"
nmcli con modify eth0 ipv4.addresses 10.24.74.172/24
nmcli con modify eth0 ipv4.method manual
nmcli con modify eth0 connection.autoconnect yes

echo "Setup IP  eth1"
nmcli con modify eth1 ipv4.addresses 10.24.44.172/24
nmcli con modify eth1 ipv4.gateway 10.24.44.1
nmcli con modify eth1 ipv4.dns 130.130.130.130
nmcli con modify eth1 ipv4.method manual
nmcli con modify eth1 connection.autoconnect yes

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
yum -y install centos-release-openstack-train

yum -y upgrade

yum -y install crudini wget vim

yum -y install python-openstackclient openstack-selinux python2-PyMySQL

yum -y update
```

### 3.2.2. Cài đặt NTP 

#### 3.2.2.1. Cài đặt NTP trên controller
---

Cài đặt đồng bộ thời gian cho `controller1`. Trong hướng dẫn này sử dụng chrony để làm NTP. 

```
yum -y install chrony
```

Sao lưu file cấu hình của NTP

```
cp /etc/chrony.conf /etc/chrony.conf.orig
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
^* 10.24.44.171                 3   6    17    13  -7869ns[ -118us] +/-   24ms

```

#### 3.2.2.2. Cài đặt NTP trên compute
---

Thực hiện bước cài đặt và cấu hình cho `compute1`

Truy cập vào máy compute1 và thực hiện cấu hình NTP như sau.

```
yum install -y chrony 
```

Sao lưu file cấu hình của NTP

```
cp /etc/chrony.conf /etc/chrony.conf.orig
```

Cấu hình chrony, lưu ý thay địa chỉ NTP server cho phù hợp. Trong ví dụ này sử dụng IP NTP trong hệ thống LAB của tôi.

```
sed -i 's/server 0.centos.pool.ntp.org iburst/server 10.24.44.171 iburst/g' /etc/chrony.conf

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

- Thực hiện cài đặt memcache trên `Controller1`

Cài đặt memcache

```
yum -y install memcached python-memcached
```

Sao lưu file cấu hình của memcache

```
cp /etc/sysconfig/memcached /etc/sysconfig/memcached.orig
```

Sửa file cấu hình của memcached

```
sed -i "s/-l 127.0.0.1,::1/-l 10.24.44.171/g" /etc/sysconfig/memcached
```

Khởi động lại memcached

```
systemctl enable memcached.service

systemctl restart memcached.service
```


### 3.2.4. Cài đặt & cấu hình MariaDB trên máy Controller
--- 

- Thực hiện cài đặt mariađb trên `controller1`

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
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'Welcome789' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'Welcome789' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' IDENTIFIED BY 'Welcome789' WITH GRANT OPTION ;FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.24.44.171' IDENTIFIED BY 'Welcome789' WITH GRANT OPTION ;FLUSH PRIVILEGES;
DROP USER 'root'@'::1';
```

### 3.2.5. Cài đặt & cấu hình rabbitmq trên máy controller
---

- Chỉ cần thực hiện cài đặt rabbitmq trên node controller1

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
rabbitmqctl add_user openstack Welcome789

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

Chỉ thực hiện bước cài này trên `controller1`

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

sed -i '/ETCD_LISTEN_PEER_URLS=/cETCD_LISTEN_PEER_URLS="http://10.24.44.171:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_LISTEN_CLIENT_URLS=/cETCD_LISTEN_CLIENT_URLS="http://10.24.44.171:2379"' /etc/etcd/etcd.conf

sed -i '/ETCD_NAME=/cETCD_NAME="controller1"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_ADVERTISE_PEER_URLS=/cETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.24.44.171:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_ADVERTISE_CLIENT_URLS=/cETCD_ADVERTISE_CLIENT_URLS="http://10.24.44.171:2379"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_CLUSTER=/cETCD_INITIAL_CLUSTER="controller1=http://10.24.44.171:2380"' /etc/etcd/etcd.conf

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
           └─14392 /usr/bin/etcd --name=controller1 --data-dir=/var/lib/etcd/default.etcd --listen-client-urls=http://10.24.44.171:2379

Dec 25 21:28:57 controller1 etcd[14392]: af176767531bba91 received MsgVoteResp from af176767531bba91 at term 2
Dec 25 21:28:57 controller1 etcd[14392]: af176767531bba91 became leader at term 2
Dec 25 21:28:57 controller1 etcd[14392]: raft.node: af176767531bba91 elected leader af176767531bba91 at term 2
Dec 25 21:28:57 controller1 etcd[14392]: published {Name:controller1 ClientURLs:[http://10.24.44.171:2379]} to cluster 39e2d6f9b633ec98
Dec 25 21:28:57 controller1 etcd[14392]: setting up the initial cluster version to 3.3
Dec 25 21:28:57 controller1 etcd[14392]: ready to serve client requests
Dec 25 21:28:57 controller1 etcd[14392]: serving insecure client requests on 10.24.44.171:2379, this is strongly discouraged!
Dec 25 21:28:57 controller1 systemd[1]: Started Etcd Server.
Dec 25 21:28:57 controller1 etcd[14392]: set the initial cluster version to 3.3
Dec 25 21:28:57 controller1 etcd[14392]: enabled capabilities for version 3.3
```

### 3.2.7. Cài đặt và cấu hình Keystone

Keystone được cài đặt trên controller.

Tạo database, user và phân quyền cho keystone
- Tên database: `keystone`
- Tên user của database: `keystone`
- Mật khẩu: `Welcome789`

```
mysql -uroot -pWelcome789 -e "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'10.24.44.171' IDENTIFIED BY 'Welcome789';
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
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:Welcome789@10.24.44.171/keystone

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
keystone-manage bootstrap --bootstrap-password Welcome789 \
--bootstrap-admin-url http://10.24.44.171:5000/v3/ \
--bootstrap-internal-url http://10.24.44.171:5000/v3/ \
--bootstrap-public-url http://10.24.44.171:5000/v3/ \
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
export OS_PASSWORD=Welcome789
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://10.24.44.171:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
```

- Phân quyền thực thi file

```
chmod +x  /root/admin-openrc
```

- Khai báo vào profile

```
cat  /root/admin-openrc >> /etc/profile
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
openstack user create demo --domain default --password Welcome789
openstack role create user
openstack role add --project demo --user demo user
```

Kết thúc bước cài đặt keystone. Chuyển sang bước cài đặt tiếp theo.

### 3.2.8. Cài đặt và cấu hình Glance

Tạo database cho glance

```
mysql -uroot -pWelcome789 -e "CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'10.24.44.171' IDENTIFIED BY 'Welcome789';
FLUSH PRIVILEGES;"
```

Khai báo user cho service glance

Thực thi biến môi trường để sử dụng được CLI của OpenStack

```
source /root/admin-openrc
```

Tạo user, project cho glance 

```
openstack user create  glance --domain default --password Welcome789

openstack role add --project service --user glance admin

openstack service create --name glance --description "OpenStack Image" image

openstack endpoint create --region RegionOne image public http://10.24.44.171:9292

openstack endpoint create --region RegionOne image internal http://10.24.44.171:9292

openstack endpoint create --region RegionOne image admin http://10.24.44.171:9292
```

Cài đặt glance 

Cài đặt glance và các gói cần thiết.

```
yum install -y openstack-glance

yum install -y MySQL-python

yum install -y python-devel
```

Sao lưu file cấu hình glance 

```
cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.orig 
```

Cấu hình glance 

```
crudini --set /etc/glance/glance-api.conf database connection  mysql+pymysql://glance:Welcome789@10.24.44.171/glance

crudini --set /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri http://10.24.44.171:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url  http://10.24.44.171:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password 
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password Welcome789

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
mysql -uroot -pWelcome789 -e "CREATE DATABASE placement;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'10.24.44.171' IDENTIFIED BY 'Welcome789';
FLUSH PRIVILEGES;"
```

Khai báo endpoint, service cho placement

Tạo service, gán quyền, enpoint cho placement.

```
openstack user create  placement --domain default --password Welcome789

openstack role add --project service --user placement admin

openstack service create --name placement --description "Placement API" placement

openstack endpoint create --region RegionOne placement public http://10.24.44.171:8778

openstack endpoint create --region RegionOne placement internal http://10.24.44.171:8778

openstack endpoint create --region RegionOne placement admin http://10.24.44.171:8778
```

Cài đặt placement 

```
yum install -y openstack-placement-api
```

Sao lưu file cấu hình của placement

```
cp /etc/placement/placement.conf /etc/placement/placement.conf.orig
```

Cấu hình placement 

```
crudini --set  /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:Welcome789@10.24.44.171/placement
crudini --set  /etc/placement/placement.conf api auth_strategy keystone
crudini --set  /etc/placement/placement.conf keystone_authtoken auth_url  http://10.24.44.171:5000/v3
crudini --set  /etc/placement/placement.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set  /etc/placement/placement.conf keystone_authtoken auth_type password
crudini --set  /etc/placement/placement.conf keystone_authtoken project_domain_name Default
crudini --set  /etc/placement/placement.conf keystone_authtoken user_domain_name Default
crudini --set  /etc/placement/placement.conf keystone_authtoken project_name service
crudini --set  /etc/placement/placement.conf keystone_authtoken username placement
crudini --set  /etc/placement/placement.conf keystone_authtoken password Welcome789
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
mysql -uroot -pWelcome789 -e "CREATE DATABASE nova_api;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'10.24.44.171' IDENTIFIED BY 'Welcome789';

CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'10.24.44.171' IDENTIFIED BY 'Welcome789';

CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'10.24.44.171' IDENTIFIED BY 'Welcome789';
FLUSH PRIVILEGES;"
```

Tạo endpoint cho nova

```
openstack user create nova --domain default --password Welcome789
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne compute public http://10.24.44.171:8774/v2.1

openstack endpoint create --region RegionOne compute internal http://10.24.44.171:8774/v2.1

openstack endpoint create --region RegionOne compute admin http://10.24.44.171:8774/v2.1
```

Cài đặt các gói cho nova

```
yum install -y openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler
```

Sao lưu file cấu hình của nova

```
cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
```

Cấu hình cho nova

```
crudini --set /etc/nova/nova.conf DEFAULT my_ip 10.24.44.171
crudini --set /etc/nova/nova.conf DEFAULT use_neutron true
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:Welcome789@10.24.44.171:5672/

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:Welcome789@10.24.44.171/nova_api
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:Welcome789@10.24.44.171/nova
crudini --set /etc/nova/nova.conf api connection  mysql+pymysql://nova:Welcome789@10.24.44.171/nova

crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://10.24.44.171:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://10.24.44.171:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password Welcome789

crudini --set /etc/nova/nova.conf vnc enabled true 
crudini --set /etc/nova/nova.conf vnc server_listen \$my_ip
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip

crudini --set /etc/nova/nova.conf glance api_servers http://10.24.44.171:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://10.24.44.171:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password Welcome789

crudini --set /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300

crudini --set /etc/nova/nova.conf neutron url http://10.24.44.171:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://10.24.44.171:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name Default
crudini --set /etc/nova/nova.conf neutron user_domain_name Default
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password Welcome789
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret Welcome789
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
| cell0 | 00000000-0000-0000-0000-000000000000 |     none:/    | mysql+pymysql://nova:****@10.24.44.171/nova_cell0 |  False   |
| cell1 | d16d0f3c-a3ba-493a-8885-ebae73bd3bf5 |    rabbit:    |    mysql+pymysql://nova:****@10.24.44.171/nova    |  False   |
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
|  1 | nova-scheduler | controller1 | internal | enabled | up    | 2019-12-26T09:38:55.000000 |
|  3 | nova-conductor | controller1 | internal | enabled | up    | 2019-12-26T09:38:54.000000 |
+----+----------------+-------------+----------+---------+-------+----------------------------+
```

#### 3.2.11.2 Cài đặt nova trên Compute

Thực hiện các bước này trên máy chủ `Compute1`

Cài đặt các gói của nova

```
yum install -y python-openstackclient openstack-selinux openstack-utils

yum install -y openstack-nova-compute
```

Sao lưu file cấu hình của nova 

```
cp  /etc/nova/nova.conf  /etc/nova/nova.conf.orig
```

Cấu hình nova

```
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:Welcome789@10.24.44.171
crudini --set /etc/nova/nova.conf DEFAULT my_ip 192.168.80.132
crudini --set /etc/nova/nova.conf DEFAULT use_neutron true
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:Welcome789@10.24.44.171/nova_api

crudini --set /etc/nova/nova.conf database connection = mysql+pymysql://nova:Welcome789@10.24.44.171/nova

crudini --set /etc/nova/nova.conf api auth_strategy keystone

crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://10.24.44.171:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://10.24.44.171:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password Welcome789

crudini --set /etc/nova/nova.conf vnc enabled true
crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://10.24.44.171:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf glance api_servers http://10.24.44.171:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://10.24.44.171:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password Welcome789

crudini --set /etc/nova/nova.conf libvirt virt_type  $(count=$(egrep -c '(vmx|svm)' /proc/cpuinfo); if [ $count -eq 0 ];then   echo "qemu"; else   echo "kvm"; fi)

```

Khởi động lại nova

```
systemctl enable libvirtd.service openstack-nova-compute.service

systemctl start libvirtd.service openstack-nova-compute.service
```


#### 3.2.11.2  Thêm node compute vào hệ thống.

Truy cập vào máy chủ `controller1` để cập nhật việc khai báo `compute1` tham gia vào hệ thống.

Login vào máy chủ controller và thực hiện lệnh dưới để kiểm tra xem compute1 đã up hay chưa.

```
source /root/admin-openrc

openstack compute service list --service nova-compute
```

Kết quả ta sẽ thấy như bên dưới là ok.

```
+----+--------------+----------+------+---------+-------+----------------------------+
| ID | Binary       | Host     | Zone | Status  | State | Updated At                 |
+----+--------------+----------+------+---------+-------+----------------------------+
|  6 | nova-compute | compute1 | nova | enabled | up    | 2019-12-26T15:52:36.000000 |
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
Checking host mapping for compute host 'compute1': d6c24463-a6f1-4457-848b-e1f83cc2fde8
Creating host mapping for compute host 'compute1': d6c24463-a6f1-4457-848b-e1f83cc2fde8
Found 1 unmapped computes in cell: d16d0f3c-a3ba-493a-8885-ebae73bd3bf5
```

Kiểm tra lại xem các dịch vụ của nova hoạt động hay chưa bằng lệnh ```openstack compute service list```

```
[root@controller1 ~]# openstack compute service list
+----+----------------+-------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host        | Zone     | Status  | State | Updated At                 |
+----+----------------+-------------+----------+---------+-------+----------------------------+
|  5 | nova-conductor | controller1 | internal | enabled | up    | 2020-04-10T08:48:01.000000 |
|  7 | nova-scheduler | controller1 | internal | enabled | up    | 2020-04-10T08:48:03.000000 |
|  8 | nova-compute   | compute1    | nova     | enabled | up    | 2020-04-10T08:47:58.000000 |
+----+----------------+-------------+----------+---------+-------+----------------------------+

```


### 3.2.12. Cài đặt và cấu hình Neutron
### 3.2.12.1 Cài đặt và cấu hình Neutron trên Controller.

Tạo database cho neutron

```
mysql -uroot -pWelcome789 -e "CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'Welcome789';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'10.24.44.171' IDENTIFIED BY 'Welcome789';"
```

Tạo project, user, endpoint cho neutron

```
openstack user create neutron --domain default --password Welcome789

openstack role add --project service --user neutron admin

openstack service create --name neutron --description "OpenStack Compute" network

openstack endpoint create --region RegionOne network public http://10.24.44.171:9696

openstack endpoint create --region RegionOne network internal http://10.24.44.171:9696

openstack endpoint create --region RegionOne network admin http://10.24.44.171:9696
```

Cài đặt neutron cho controller

```
yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables 
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
crudini --set  /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:Welcome789@10.24.44.171
crudini --set  /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set  /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True 

crudini --set  /etc/neutron/neutron.conf database connection  mysql+pymysql://neutron:Welcome789@10.24.44.171/neutron

crudini --set  /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://10.24.44.171:5000
crudini --set  /etc/neutron/neutron.conf keystone_authtoken auth_url http://10.24.44.171:5000
crudini --set  /etc/neutron/neutron.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set  /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set  /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set  /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set  /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set  /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set  /etc/neutron/neutron.conf keystone_authtoken password Welcome789

crudini --set /etc/neutron/neutron.conf nova auth_url http://10.24.44.171:5000
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name Default
crudini --set /etc/neutron/neutron.conf nova user_domain_name Default
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password Welcome789

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
crudini --set /etc/nova/nova.conf neutron url http://10.24.44.171:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://10.24.44.171:5000
crudini --set /etc/nova/nova.conf neutron auth_type password
crudini --set /etc/nova/nova.conf neutron project_domain_name Default
crudini --set /etc/nova/nova.conf neutron user_domain_name Default
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password Welcome789
```

Cài đặt neutron 

```
yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables ipset
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
crudini --set /etc/neutron/neutron.conf DEFAULT transport_url rabbit://openstack:Welcome789@10.24.44.171
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes true
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes true

crudini --set /etc/neutron/neutron.conf keystone_authtoken www_authenticate_uri http://10.24.44.171:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://10.24.44.171:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers 10.24.44.171:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name Default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name Default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password Welcome789

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
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_host 10.24.44.171
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret Welcome789
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

Sau khi cài đặt xong neutron trên controller, thực hiện lệnh `openstack network agent list` để kiểm tra xem các thành phần của neutron hoạt động đúng hay chưa.

```
[root@controller1 ~]# openstack network agent list
+--------------------------------------+--------------------+-------------+-------------------+-------+-------+---------------------------+
| ID                                   | Agent Type         | Host        | Availability Zone | Alive | State | Binary                    |
+--------------------------------------+--------------------+-------------+-------------------+-------+-------+---------------------------+
| 367e25e1-340a-49a3-a3fe-b12b2739d7a6 | Linux bridge agent | compute1    | None              | :-)   | UP    | neutron-linuxbridge-agent |
| 7ed2cf8c-57f7-423d-b05c-cd4fee2545a3 | Linux bridge agent | controller1 | None              | :-)   | UP    | neutron-linuxbridge-agent |
| 936b0562-142d-40d8-8a8b-88cd87a2bf8b | Metadata agent     | compute1    | None              | :-)   | UP    | neutron-metadata-agent    |
| a7b080fe-76c4-4bb4-a4b3-a2941822aded | Metadata agent     | controller1 | None              | :-)   | UP    | neutron-metadata-agent    |
| e18e802f-db3f-46c2-b8a9-f39da87d08b5 | DHCP agent         | controller1 | nova              | :-)   | UP    | neutron-dhcp-agent        |
| fe874639-d158-49d1-83cf-d3841ce6ac30 | DHCP agent         | compute1    | nova              | :-)   | UP    | neutron-dhcp-agent        |
+--------------------------------------+--------------------+-------------+-------------------+-------+-------+---------------------------+
```

# 4. Cài đặt horizon

Cài đặt gói dashboard cho OpenStack

```
yum install -y openstack-dashboard
```

Sao lưu file `/etc/openstack-dashboard/local_settings`

```
cp /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.orig
```

- Sửa các dòng ở file `/etc/openstack-dashboard/local_settings` để có nội dung giống như bên dưới

```
import os
from django.utils.translation import ugettext_lazy as _
from openstack_dashboard.settings import HORIZON_CONFIG
DEBUG = False
ALLOWED_HOSTS = ['*']
LOCAL_PATH = '/tmp'
SECRET_KEY='815188a7493add38560f'
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': '10.24.44.171:11211',
    }
}
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
OPENSTACK_HOST = "10.24.44.171"
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}

OPENSTACK_NEUTRON_NETWORK = {
    'enable_auto_allocated_network': False,
    'enable_distributed_router': False,
    'enable_fip_topology_check': True,
    'enable_ha_router': False,
    'enable_ipv6': True,
    # TODO(amotoki): Drop OPENSTACK_NEUTRON_NETWORK completely from here.
    # enable_quotas has the different default value here.
    'enable_quotas': True,
    'enable_rbac_policy': True,
    'enable_router': True,
    'default_dns_nameservers': [],
    'supported_provider_types': ['*'],
    'segmentation_id_range': {},
    'extra_provider_types': {},
    'supported_vnic_types': ['*'],
    'physical_networks': [],
}
TIME_ZONE = "Asia/Ho_Chi_Minh"
LOGGING = {
    'version': 1,
    # When set to True this will disable all logging except
    # for loggers specified in this configuration dictionary. Note that
    # if nothing is specified here and disable_existing_loggers is True,
    # django.db.backends will still log unless it is disabled explicitly.
    'disable_existing_loggers': False,
    # If apache2 mod_wsgi is used to deploy OpenStack dashboard
    # timestamp is output by mod_wsgi. If WSGI framework you use does not
    # output timestamp for logging, add %(asctime)s in the following
    # format definitions.
    'formatters': {
        'console': {
            'format': '%(levelname)s %(name)s %(message)s'
        },
        'operation': {
            # The format of "%(message)s" is defined by
            # OPERATION_LOG_OPTIONS['format']
            'format': '%(message)s'
        },
    },
    'handlers': {
        'null': {
            'level': 'DEBUG',
            'class': 'logging.NullHandler',
        },
        'console': {
            # Set the level to "DEBUG" for verbose output logging.
            'level': 'DEBUG' if DEBUG else 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'console',
        },
        'operation': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'operation',
        },
    },
    'loggers': {
        'horizon': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'horizon.operation_log': {
            'handlers': ['operation'],
            'level': 'INFO',
            'propagate': False,
        },
        'openstack_dashboard': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'novaclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'cinderclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'keystoneauth': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'keystoneclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'glanceclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'neutronclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'swiftclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'oslo_policy': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'openstack_auth': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'django': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        # Logging from django.db.backends is VERY verbose, send to null
        # by default.
        'django.db.backends': {
            'handlers': ['null'],
            'propagate': False,
        },
        'requests': {
            'handlers': ['null'],
            'propagate': False,
        },
        'urllib3': {
            'handlers': ['null'],
            'propagate': False,
        },
        'chardet.charsetprober': {
            'handlers': ['null'],
            'propagate': False,
        },
        'iso8601': {
            'handlers': ['null'],
            'propagate': False,
        },
        'scss': {
            'handlers': ['null'],
            'propagate': False,
        },
    },
}
SECURITY_GROUP_RULES = {
    'all_tcp': {
        'name': _('All TCP'),
        'ip_protocol': 'tcp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_udp': {
        'name': _('All UDP'),
        'ip_protocol': 'udp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_icmp': {
        'name': _('All ICMP'),
        'ip_protocol': 'icmp',
        'from_port': '-1',
        'to_port': '-1',
    },
    'ssh': {
        'name': 'SSH',
        'ip_protocol': 'tcp',
        'from_port': '22',
        'to_port': '22',
    },
    'smtp': {
        'name': 'SMTP',
        'ip_protocol': 'tcp',
        'from_port': '25',
        'to_port': '25',
    },
    'dns': {
        'name': 'DNS',
        'ip_protocol': 'tcp',
        'from_port': '53',
        'to_port': '53',
    },
    'http': {
        'name': 'HTTP',
        'ip_protocol': 'tcp',
        'from_port': '80',
        'to_port': '80',
    },
    'pop3': {
        'name': 'POP3',
        'ip_protocol': 'tcp',
        'from_port': '110',
        'to_port': '110',
    },
    'imap': {
        'name': 'IMAP',
        'ip_protocol': 'tcp',
        'from_port': '143',
        'to_port': '143',
    },
    'ldap': {
        'name': 'LDAP',
        'ip_protocol': 'tcp',
        'from_port': '389',
        'to_port': '389',
    },
    'https': {
        'name': 'HTTPS',
        'ip_protocol': 'tcp',
        'from_port': '443',
        'to_port': '443',
    },
    'smtps': {
        'name': 'SMTPS',
        'ip_protocol': 'tcp',
        'from_port': '465',
        'to_port': '465',
    },
    'imaps': {
        'name': 'IMAPS',
        'ip_protocol': 'tcp',
        'from_port': '993',
        'to_port': '993',
    },
    'pop3s': {
        'name': 'POP3S',
        'ip_protocol': 'tcp',
        'from_port': '995',
        'to_port': '995',
    },
    'ms_sql': {
        'name': 'MS SQL',
        'ip_protocol': 'tcp',
        'from_port': '1433',
        'to_port': '1433',
    },
    'mysql': {
        'name': 'MYSQL',
        'ip_protocol': 'tcp',
        'from_port': '3306',
        'to_port': '3306',
    },
    'rdp': {
        'name': 'RDP',
        'ip_protocol': 'tcp',
        'from_port': '3389',
        'to_port': '3389',
    },
}
```

Thực hiện các lệnh sau

```
cd /usr/share/openstack-dashboard

python manage.py make_web_conf --apache > /etc/httpd/conf.d/openstack-dashboard.conf

ln -s /etc/openstack-dashboard /usr/share/openstack-dashboard/openstack_dashboard/conf

systemctl enable httpd.service

systemctl restart httpd.service
 
systemctl restart memcached.service
```

Truy cập vào trang chủ với địa chỉ `http://10.24.44.171`

# 5. Hướng dẫn sử dụng 
## 5.1. Khai báo network, router 

## 5.2. Hướng dẫn tạo VM.




