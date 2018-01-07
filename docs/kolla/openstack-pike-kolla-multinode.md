# Hướng dẫn triển khai OpenStack sử dụng công cụ OpenStack kolla-ansible

- Mục tiêu của `OpenStack kolla-ansible` là để:
  - Kolla dùng để triển khai các service (keystone, nova, neutron ....và cả của CEPH) bằng docker - hay còn gọi là containerized (container hóa). Lợi thế của docker là nhanh - nhỏ - nhẹ.
  - Asible được sử dụng để tự động hóa việc cài đặt các service - tự động hóa việc pull, run .. các images của docker.
  - Dùng `kolla-ansible` trong được môi trường production.
  - OpenStack kolla-ansible thích hợp với những người có kinh nghiệm về docker và ansible (tất nhiên cũng có chút hiểu biết về OpenStack nữa).
  - Dùng kolla-ansible để triển khai OpenStack giúp tiết kiệm thời gian cài đặt cho người triển khai. Đa số các images (images trong khái niệm của docker nhé) của hầu hết các project trong OpenStack đã được cộng đồng đóng gói và update thường xuyên.

## 1. Môi trường
- Môi trường LAB trên KVM hoặc VMware - (có thể ánh xạ và áp dụng cho máy vật lý - baremetal)
- Các máy cài đặt CentOS 7.4 - 64 bit
- Phiên bản OpenStack: OpenStack Pike
- Các project cài đặt cho OpenStack gồm:
- Network trong Neutron của OpenStack: Sử dụng cả provider network và selfservice network. Dải mạng cho `provider network` được liệt kê ở dưới.


## 2. Mô hình LAB

- Gồm 03 node: 
  - Node1: Máy cài `kolla-ansible`
  - Node2: Controller1 (target node)
  - Node2: Compute1 (target node)
  - Node3: Compute2 (target node) - node này sẽ được add vào sau khi cài xong OpenStack trên `Controller` và `Compute1`

  
## 3. IP Planning

- IP Planning cho các máy.

- Lưu ý:
  - Dải provider network (máy ảo do OpenStack sinh ra sẽ kết nối qua dải này)
  
## 4. Bước chuẩn bị.

### 4.1. Cấu hình cơ bản.
- SSH vào các node với quyền root và thực hiện lần lượt các bước dưới.

#### 4.1.1. Đặt hostname, IP và cấu hình các gói cơ bản cho `deployserver` 

- Đặt hostname cho `deployserver`

  ```sh
  hostnamectl set-hostname deployserver
  ```

- Đặt IP cho `deployserver` và cấu hình cơ bản

  ```sh
  echo "Setup IP  eth0"
  nmcli c modify eth0 ipv4.addresses 10.10.10.200/24
  nmcli c modify eth0 ipv4.method manual
  nmcli con mod eth0 connection.autoconnect yes

  echo "Setup IP  eth1"
  nmcli c modify eth1 ipv4.addresses 172.16.68.200/24
  nmcli c modify eth1 ipv4.gateway 172.16.68.1
  nmcli c modify eth1 ipv4.dns 8.8.8.8
  nmcli c modify eth1 ipv4.method manual
  nmcli con mod eth1 connection.autoconnect yes

  echo "Setup IP  eth2"
  nmcli c modify eth2 ipv4.addresses 192.168.20.200/24
  nmcli c modify eth2 ipv4.method manual
  nmcli con mod eth2 connection.autoconnect yes

  sudo systemctl disable firewalld
  sudo systemctl stop firewalld
  sudo systemctl disable NetworkManager
  sudo systemctl stop NetworkManager
  sudo systemctl enable network
  sudo systemctl start network
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  ```

- Khởi động lại, sau đó trong các bước tiếp theo đăng nhập bằng IP mới và tài khoản `root`

  ```sh
  init 6
  ```

#### 4.1.2. Đặt hostname, IP và cấu hình các gói cơ bản cho `controller1` 


- Đặt hostname cho `deployserver`

  ```sh
  hostnamectl set-hostname controller1
  ```

- Đặt IP cho `controller1` và cấu hình cơ bản

  ```
  echo "Setup IP  eth0"
  nmcli c modify eth0 ipv4.addresses 10.10.10.201/24
  nmcli c modify eth0 ipv4.method manual
  nmcli con mod eth0 connection.autoconnect yes

  echo "Setup IP  eth1"
  nmcli c modify eth1 ipv4.addresses 172.16.68.201/24
  nmcli c modify eth1 ipv4.gateway 172.16.68.1
  nmcli c modify eth1 ipv4.dns 8.8.8.8
  nmcli c modify eth1 ipv4.method manual
  nmcli con mod eth1 connection.autoconnect yes

  echo "Setup IP  eth2"
  nmcli c modify eth2 ipv4.addresses 192.168.20.201/24
  nmcli c modify eth2 ipv4.method manual
  nmcli con mod eth2 connection.autoconnect yes

  sudo systemctl disable firewalld
  sudo systemctl stop firewalld
  sudo systemctl disable NetworkManager
  sudo systemctl stop NetworkManager
  sudo systemctl enable network
  sudo systemctl start network
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  ```

- Khởi động lại, sau đó trong các bước tiếp theo đăng nhập bằng IP mới và tài khoản `root`

  ```sh
  init 6
  ```

#### 4.1.3. Đặt hostname, IP và cấu hình các gói cơ bản cho `compute1` 


- Đặt hostname cho `compute1`

  ```sh
  hostnamectl set-hostname compute1
  ```

- Đặt IP cho `compute1` và cấu hình cơ bản

  ```sh
  echo "Setup IP  eth0"
  nmcli c modify eth0 ipv4.addresses 10.10.10.202/24
  nmcli c modify eth0 ipv4.method manual
  nmcli con mod eth0 connection.autoconnect yes

  echo "Setup IP  eth1"
  nmcli c modify eth1 ipv4.addresses 172.16.68.202/24
  nmcli c modify eth1 ipv4.gateway 172.16.68.1
  nmcli c modify eth1 ipv4.dns 8.8.8.8
  nmcli c modify eth1 ipv4.method manual
  nmcli con mod eth1 connection.autoconnect yes

  echo "Setup IP  eth2"
  nmcli c modify eth2 ipv4.addresses 192.168.20.202/24
  nmcli c modify eth2 ipv4.method manual
  nmcli con mod eth2 connection.autoconnect yes

  sudo systemctl disable firewalld
  sudo systemctl stop firewalld
  sudo systemctl disable NetworkManager
  sudo systemctl stop NetworkManager
  sudo systemctl enable network
  sudo systemctl start network
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  ```

- Khởi động lại, sau đó trong các bước tiếp theo đăng nhập bằng IP mới và tài khoản `root`

  ```sh
  init 6
  ```
  
#### 4.1.4. Đặt hostname, IP và cấu hình các gói cơ bản cho `compute2` 


- Đặt hostname cho `compute2`

  ```sh
  hostnamectl set-hostname compute2
  ```
  
- - Đặt IP cho `compute2` và cấu hình cơ bản

  ```sh
  echo "Setup IP  eth0"
  nmcli c modify eth0 ipv4.addresses 10.10.10.203/24
  nmcli c modify eth0 ipv4.method manual
  nmcli con mod eth0 connection.autoconnect yes

  echo "Setup IP  eth1"
  nmcli c modify eth1 ipv4.addresses 172.16.68.203/24
  nmcli c modify eth1 ipv4.gateway 172.16.68.1
  nmcli c modify eth1 ipv4.dns 8.8.8.8
  nmcli c modify eth1 ipv4.method manual
  nmcli con mod eth1 connection.autoconnect yes

  echo "Setup IP  eth2"
  nmcli c modify eth2 ipv4.addresses 192.168.20.203/24
  nmcli c modify eth2 ipv4.method manual
  nmcli con mod eth2 connection.autoconnect yes

  sudo systemctl disable firewalld
  sudo systemctl stop firewalld
  sudo systemctl disable NetworkManager
  sudo systemctl stop NetworkManager
  sudo systemctl enable network
  sudo systemctl start network
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  ```


Tới đây đã xong bước setup cơ bản, nếu sử dụng trên các môi trường ảo hóa thì có thể snapshot lại để dùng lại nhiều lần.
  
### 4.2. Cấu hình các gói hỗ trợ cho việc sử dụng kolla-ansible

#### 4.2.1. Thực hiện trên node `deployserver`

- Cài đặt các gói phụ trợ cho `kolla-ansible` trên `deployserver`
  ```
  yum install -y epel-release
  yum update -y

  yum install -y git wget ansible gcc python-devel python-pip yum-utils byobu
  ```

- Cài đặt docker trên `deployserver`

  ```sh
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

  yum install -y docker-ce
  ```

- Cấu hình cho docker 
```sh
mkdir /etc/systemd/system/docker.service.d

tee /etc/systemd/system/docker.service.d/kolla.conf << 'EOF'
[Service]
MountFlags=shared
EOF
```

- Khai báo registry cho các host cài docker.

```sh
sed -i "s/\/usr\/bin\/dockerd/\/usr\/bin\/dockerd --insecure-registry 172.16.68.202:4000/g" /usr/lib/systemd/system/docker.service
```