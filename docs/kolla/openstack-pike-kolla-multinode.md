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
