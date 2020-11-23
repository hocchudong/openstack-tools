# Hướng dẫn triển khai OpenStack Ussuri trên Centos 8 sử dụng KOLLA

## Mô hình AIO

### Mô trường
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


### Chuẩn bị

Đặt hostname

`hostnamectl set-hostname opsaio`

Update hệ điều hành

```
dnf install -y epel-release
dnf update -y
```

Cấu hình Network

```
echo "Setup IP ens3"
nmcli c modify ens3 ipv4.addresses 10.10.30.61/24
nmcli c modify ens3 ipv4.gateway 10.10.30.1
nmcli c modify ens3 ipv4.dns 8.8.8.8
nmcli c modify ens3 ipv4.method manual
nmcli con mod ens3 connection.autoconnect yes

echo "Setup IP ens8"
nmcli c modify ens8 ipv4.addresses 10.10.31.61/24
nmcli c modify ens8 ipv4.method manual
nmcli con mod ens8 connection.autoconnect yes
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
dnf install chrony -y
timedatectl set-timezone Asia/Ho_Chi_Minh
sed -i 's/2.centos.pool.ntp.org/2.vn.pool.ntp.org/g' /etc/chrony.conf
systemctl enable chronyd.service
systemctl restart chronyd.service
chronyc sources
```

Khởi động lại

`init 6`

Lưu ý: Tạo bước này các bạn nên snapshot lại VM

### Phần 2. Cài đặt Kolla Ansible

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

`ssh-copy-id root@opsaio`

Lưu ý: Tại bước này bạn cần nhập mật khẩu SSH của Node

Kiểm tra lại

`ansible -i all-in-one all -m ping`

### Phần 3. Cài đặt Openstack Train bằng Kolla Ansible

Thiết lập phần vùng LVM dành cho Cinder

```
pvcreate /dev/vdb
vgcreate cinder-volumes /dev/vdb
```

Tạo File chứa mật khẩu mặc định

`kolla-genpwd`

Cấu hình triển khai Openstack

```
cp /etc/kolla/globals.yml /etc/kolla/globals.yml.bak
cat << EOF > /etc/kolla/globals.yml
kolla_base_distro: "centos"
kolla_install_type: "source"
kolla_internal_vip_address: 10.10.30.61
network_interface: ens3
neutron_external_interface: ens8
nova_compute_virt_type: "qemu"
enable_haproxy: "no"
enable_cinder: "yes"
enable_cinder_backup: "no"
enable_cinder_backend_lvm: "yes"
EOF
```

Khởi tạo môi trường dành cho Openstack Kolla

`kolla-ansible -i all-in-one bootstrap-servers`

Kiểm tra thiết lập Kolla Ansible

`kolla-ansible -i all-in-one prechecks`

Tải các Image Openstack

`kolla-ansible -i all-in-one pull`

Cài đặt Openstack

`kolla-ansible -i all-in-one deploy`

Thiết lập File Environment Openstack

`kolla-ansible -i all-in-one post-deploy`

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