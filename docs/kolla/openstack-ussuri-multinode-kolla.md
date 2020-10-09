# Hướng dẫn triển khai OpenStack Ussuri trên Centos 8 sử dụng KOLLA

## Mô trường
1 server có cấu hình:
- OS: CentOS 8
- CPU: 4 Core
- RAM: 8 GB
- Disk: 2 ổ
    - OS (vda): 100 GB
    - Data VM (vdb): 50 GB
- Network: 2 interface
    - Dải MNGT + API + Internal Network: 10.10.30.0/24
    - Dải Provider hay External Network: 10.10.31.0/24

1 server có cấu hình:
- OS: CentOS 8
- CPU: 4 Core
- RAM: 8 GB
- Disk: 1 ổ
    - OS (vda): 100 GB
- Network: 2 interface
    - Dải MNGT + API + Internal Network: 10.10.30.0/24
    - Dải Provider hay External Network: 10.10.31.0/24

## Cài đặt
### Phần 1. Chuẩn bị

**Trên node Controller:**

Đặt hostname

`hostnamectl set-hostname controller`

Cấu hình Network

```
echo "Setup IP eth0"
nmcli c modify eth0 ipv4.addresses 10.10.30.61/24
nmcli c modify eth0 ipv4.gateway 10.10.30.1
nmcli c modify eth0 ipv4.dns 8.8.8.8
nmcli c modify eth0 ipv4.method manual
nmcli con mod eth0 connection.autoconnect yes

echo "Setup IP eth1"
nmcli c modify eth1 ipv4.addresses 10.10.31.61/24
nmcli c modify eth1 ipv4.method manual
nmcli con mod eth1 connection.autoconnect yes
```

Update hệ điều hành

```
dnf install -y epel-release
dnf update -y
```

Tắt Firewall, SELinux

```
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld
```

Cấu hình đồng bộ thời gian

```
timedatectl set-timezone Asia/Ho_Chi_Minh
systemctl enable chronyd.service
systemctl restart chronyd.service
chronyc sources
```

Tạo phân vùng Cinder LVM

```
pvcreate /dev/vdb
vgcreate cinder-volumes /dev/vdb
```

Cài đặt môi trường Python, Ansible

Cài đặt các gói hỗ trợ

`dnf install -y vim git byobu`

Cài đặt môi trường python

`dnf install python3-devel libffi-devel gcc openssl-devel python3-libselinux -y`

Cài đặt ansible

`pip3 install -U 'ansible<2.10'`

```
mkdir -p /etc/ansible
txt="[defaults]\nhost_key_checking=False\npipelining=True\nforks=100"
echo -e $txt >> /etc/ansible/ansible.cfg
```

Tắt máy và snapshot lại

**Trên node Compute**

Đặt hostname

`hostnamectl set-hostname compute`

Cấu hình Network

```
echo "Setup IP eth0"
nmcli c modify eth0 ipv4.addresses 10.10.30.62/24
nmcli c modify eth0 ipv4.gateway 10.10.30.1
nmcli c modify eth0 ipv4.dns 8.8.8.8
nmcli c modify eth0 ipv4.method manual
nmcli con mod eth0 connection.autoconnect yes

echo "Setup IP eth1"
nmcli c modify eth1 ipv4.addresses 10.10.31.62/24
nmcli c modify eth1 ipv4.method manual
nmcli con mod eth1 connection.autoconnect yes
```

Tắt Firewall, SELinux

```
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld
```

Update hệ điều hành

```
dnf install -y epel-release
dnf update -y
```

Cấu hình đồng bộ thời gian

```
timedatectl set-timezone Asia/Ho_Chi_Minh
systemctl enable chronyd.service
systemctl restart chronyd.service
chronyc sources
```

Cài đặt môi trường

```
yum install -y python-devel libffi-devel gcc openssl-devel libselinux-python
yum install -y vim git byobu
```

Tắt máy và snapshot lại

### Phần 2. Cài đặt Kolla Ansible trên node Controller

Cài đặt kolla-ansible

`pip3 install "kolla-ansible==10.1.*"`

Tạo folder

```
sudo mkdir -p /etc/kolla
sudo chown $USER:$USER /etc/kolla
```

Cấu hình Kolla Ansible mặc định

`cp /usr/local/share/kolla-ansible/etc_examples/kolla/* /etc/kolla/`

Thiết lập File Inventory Kolla Ansible

`cp /usr/local/share/kolla-ansible/ansible/inventory/* .`

Thiết lập Keypair

`ssh-keygen`

Lưu ý: Nhấn ENTER, sinh Keypair mặc định

Chuyển key

```
ssh-copy-id root@controller
ssh-copy-id root@compute
```

Lưu ý: Tại bước này bạn cần nhập mật khẩu SSH của Node

Chỉnh sửa file `multinode`

Tại section [control], điền IP node Controller

```
[control]
10.10.30.61 ansible_connection=ssh     ansible_user=root
```

Tại section [network], điền IP node Controller

```
[network]
10.10.30.61 ansible_connection=ssh     ansible_user=root
```

Tại section [monitoring], điền IP node Controller

```
[monitoring]
10.10.30.61 ansible_connection=ssh     ansible_user=root
```

Tại section [storage], điền IP các Controller

```
[storage]
10.10.30.61 ansible_connection=ssh     ansible_user=root
```

Tại section [deployment], điền IP node kolla ansible (vì ở đây ta cài đặt kolla ansible trên Controller nên ta sẽ để là localhost)

```
[deployment]
localhost  ansible_connection=ssh
```

Tại section [compute], điền IP node compute
Lưu ý: Nếu bạn có nhiều hơn 1 node compute thì thêm các dòng đó xuống phía dưới nhé.

```
[compute]
10.10.30.62 ansible_connection=ssh     ansible_user=root
```

Kiểm tra

`ansible -i multinode all -m ping`

### Phần 3. Cài đặt Openstack Train bằng Kolla Ansible

Tạo File chứa mật khẩu mặc định

`kolla-genpwd`

Cấu hình Kolla Openstack

```
cp /etc/kolla/globals.yml /etc/kolla/globals.yml.bak
cat << EOF > /etc/kolla/globals.yml
kolla_base_distro: "centos"
kolla_install_type: "source"

# Không sử dụng HA Controller (VIP RabbitMQ, MariaDB v.v)
# enable_haproxy: "no"

# Dải Mngt + admin, internal API
kolla_internal_vip_address: "10.10.30.63"
network_interface: "ens3"

# Dải Mngt Provider
neutron_external_interface: "ens8"

# Cho phép neutron sử dụng dải provider
enable_neutron_provider_networks: "yes"

nova_compute_virt_type: "qemu"

keepalived_virtual_router_id: "60"

enable_cinder: "yes"
enable_cinder_backend_lvm: "yes"
enable_cinder_backup: "no"
EOF
```

Kiểm tra lại cấu hình

`cat /etc/kolla/globals.yml | egrep -v '^#|^$'`

Sử dụng byobu để chống mất phiên khi thực hiện việc triển khai kolla-ansible để cài OpenStack

`byobu`

Thực hiện các bước cài đặt OpenStack bằng kolla-ansible.

Khởi tạo môi trường dành cho Openstack Kolla

`kolla-ansible -i multinode bootstrap-servers`

Kiểm tra thiết lập Kolla Ansible

`kolla-ansible -i multinode prechecks`

Cài đặt Openstack

`kolla-ansible -i multinode deploy`

Thiết lập File Environment Openstack

`kolla-ansible -i multinode post-deploy`

### Phần 4. Cài đặt Openstack Client

Cài đặt các gói cần thiết để tạo virtualenv
Tạo virtualen có tên là venv

```
pip3 install virtualenv
virtualenv venv
```

Source environment

`. venv/bin/activate`

Cài đặt các gói openstack client trong virtualenv

```
pip3 install python-openstackclient python-glanceclient python-neutronclient
source /etc/kolla/admin-openrc.sh
```

Kiểm tra xem OpenStack hoạt động hay chưa

`openstack token issue`