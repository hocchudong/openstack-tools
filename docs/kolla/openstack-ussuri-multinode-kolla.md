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
dnf install chrony -y
timedatectl set-timezone Asia/Ho_Chi_Minh
sed -i 's/2.centos.pool.ntp.org/2.vn.pool.ntp.org/g' /etc/chrony.conf
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

Cập nhật `pip3 install -U pip` trước khi cài đặt `ansible` để tránh bị lỗi sau
```shell
Complete output from command python setup.py egg_info:

            =============================DEBUG ASSISTANCE==========================
            If you are seeing an error here please try the following to
            successfully install cryptography:

            Upgrade to the latest pip and try again. This will fix errors for most
            users. See: https://pip.pypa.io/en/stable/installing/#upgrading-pip
            =============================DEBUG ASSISTANCE==========================

    Traceback (most recent call last):
      File "<string>", line 1, in <module>
      File "/tmp/pip-build-dpg9skiz/cryptography/setup.py", line 17, in <module>
        from setuptools_rust import RustExtension
    ModuleNotFoundError: No module named 'setuptools_rust'
```

Cài đặt ansible

`pip3 install -U 'ansible<2.10'`

hoặc `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pip3 install -U 'ansible<2.10'` để tránh gặp lỗi sau
```shell
Exception:
	Traceback (most recent call last):
	  File "/usr/lib/python3.6/site-packages/pip/basecommand.py", line 215, in main
		status = self.run(options, args)
	  File "/usr/lib/python3.6/site-packages/pip/commands/install.py", line 346, in run
		requirement_set.prepare_files(finder)
	  File "/usr/lib/python3.6/site-packages/pip/req/req_set.py", line 381, in prepare_files
		ignore_dependencies=self.ignore_dependencies))
	  File "/usr/lib/python3.6/site-packages/pip/req/req_set.py", line 623, in _prepare_file
		session=self.session, hashes=hashes)
	  File "/usr/lib/python3.6/site-packages/pip/download.py", line 822, in unpack_url
		hashes=hashes
	  File "/usr/lib/python3.6/site-packages/pip/download.py", line 664, in unpack_http_url
		unpack_file(from_path, location, content_type, link)
	  File "/usr/lib/python3.6/site-packages/pip/utils/__init__.py", line 615, in unpack_file
		untar_file(filename, location)
	  File "/usr/lib/python3.6/site-packages/pip/utils/__init__.py", line 587, in untar_file
		with open(path, 'wb') as destfp:
	UnicodeEncodeError: 'latin-1' codec can't encode characters in position 97-100: ordinal not in range(256)
```

Cấu hình ansible
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

```
dnf install chrony -y
timedatectl set-timezone Asia/Ho_Chi_Minh
sed -i 's/2.centos.pool.ntp.org/2.vn.pool.ntp.org/g' /etc/chrony.conf
systemctl enable chronyd.service
systemctl restart chronyd.service
chronyc sources
```

Cài đặt các gói hỗ trợ

`dnf install -y vim git byobu`

Cài đặt môi trường python

`dnf install python3-devel libffi-devel gcc openssl-devel python3-libselinux -y`

Tắt máy và snapshot lại

### Phần 2. Cài đặt Kolla Ansible trên node Controller

Cài đặt kolla-ansible

`pip3 install "kolla-ansible==10.2.*"` --ignore-installed PyYAML 

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
kolla_internal_vip_address: "10.10.30.61"
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
**Lưu ý:** nếu bạn đang lab trên nền tảng **OpenStack** thì hãy cấu hình **Allow-Address-Pair** để hợp thức hóa **kolla_internal_vip_address** ở cấu hình trên.

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

### Phần 5 Hướng dẫn cấu hình octavia bằng kolla-ansible

Clone repo về 

`git clone https://github.com/openstack/octavia -b stable/ussuri`

Kiểm tra password của octavia

`cat /etc/kolla/passwords.yml | grep octavia_ca_password`

Thay thế password vào file gen cert

`sed -i 's/not-secure-passphrase/4eSTukxVTs700MecknzV4zt878tgwBMNPhQf58ka/g' octavia/bin/create_single_CA_intermediate_CA.sh`

Gen cert

```
cd octavia/bin/
./create_single_CA_intermediate_CA.sh openssl.cnf
```

Copy các file cert vào thư mục cấu hình

```
mkdir -p /etc/kolla/config/octavia
cp single_ca/etc/octavia/certs/* /etc/kolla/config/octavia/
```

Chỉnh sửa file `/etc/kolla/globals.yml` thêm vào cấu hình sau

`enable_octavia: "yes"`

Sau đó reconfigure lại bằng câu lệnh

`kolla-ansible -i multinode reconfigure`

Sau khi cài đặt xong, tiến hành tạo image từ công cụ image builder

```
virtualenv /root/env-octavia
source /root/env-octavia/bin/activate
cd octavia/
pip install -r requirements.txt
cd diskimage-create
pip install -r requirements.txt
yum install -y qemu-img
yum install debootstrap -y 
./diskimage-create.sh -i ubuntu -t qcow2 -o amphora-x64-haproxy
```

Đợi cho tới khi quá trình tạo image hoàn tất.

Xem password của octavia

`cat /etc/kolla/passwords.yml | grep octavia_keystone_password`

Tạo file octavia-rc.sh

```
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=service
export OS_TENANT_NAME=service
export OS_USERNAME=octavia
export OS_PASSWORD=JZKdOSBzrrHoP94anEy4suPMCiADffU4Odhu2cGC
export OS_AUTH_URL=http://10.10.30.61:35357/v3
export OS_INTERFACE=internal
export OS_ENDPOINT_TYPE=internalURL
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=RegionOne
export OS_AUTH_PLUGIN=password
```

Kích hoạt biến môi trường

```
source octavia-rc.sh
```

Tạo image từ file image đã tạo

```
openstack image create --container-format bare --disk-format qcow2 --private --file /root/amphora-x64-haproxy.qcow2 --tag amphora amphora
```

Tạo flavor

```
openstack flavor create --ram 2048 --disk 10 --vcpus 2 amphora-2g-2c
```

Tajo keypair

```
openstack keypair create --public-key /root/.ssh/id_rsa.pub octavia_ssh_key
```

Khởi tạo Security Group và Rule cho LB Network .

````
openstack --os-region-name=RegionOne security group create lb-mgmt-sec-grp
openstack --os-region-name=RegionOne security group rule create --protocol icmp lb-mgmt-sec-grp
openstack --os-region-name=RegionOne security group rule create --protocol tcp --dst-port 22 lb-mgmt-sec-grp
openstack --os-region-name=RegionOne security group rule create --protocol tcp --dst-port 9443 lb-mgmt-sec-grp
openstack --os-region-name=RegionOne security group rule create --protocol icmpv6 --ethertype IPv6 --remote-ip ::/0 lb-mgmt-sec-grp
openstack --os-region-name=RegionOne security group rule create --protocol tcp --dst-port 22 --ethertype IPv6 --remote-ip ::/0 lb-mgmt-sec-grp
openstack --os-region-name=RegionOne security group rule create --protocol tcp --dst-port 9443 --ethertype IPv6 --remote-ip ::/0 lb-mgmt-sec-grp
```

Khởi tạo Security group cho Health manager ( heatbeat tới các VM Load Balanacer ) . Đây là mạng liên hệ giữa Controller và các VM Load Balancer.

```
openstack --os-region-name=RegionOne security group create lb-health-mgr-sec-grp
openstack --os-region-name=RegionOne security group rule create --protocol udp --dst-port 5555 lb-health-mgr-sec-grp
openstack --os-region-name=RegionOne security group rule create --protocol udp --dst-port 5555 --ethertype IPv6 --remote-ip ::/0 lb-health-mgr-sec-grp
```

Khởi tạo LB Network

```
neutron --os-region-name=RegionOne net-create lb-mgmt-net1
neutron --os-region-name=RegionOne subnet-create --name lb-mgmt-subnet1 lb-mgmt-net1 192.168.199.0/24 --no-gateway
```

Khởi tạo port trên neutron sử dụng Security Group lb-health-mgr-sec-grp, sau đó gắn vào openvswitch cho Health Manager ( thực hiện trên tất cả node controller )

```
neutron port-create --name octavia-health-manager-region-one-listen-port --security-group lb-health-mgr-sec-grp --device-owner Octavia:health-mgr --binding:host_id=controller lb-mgmt-net1
```

Lưu lại thông tin của port

<img src="https://i.imgur.com/y4eQHFW.png">

Ta sẽ add nó vào ovs

```
docker exec -it openvswitch_vswitchd bash
ovs-vsctl --may-exist add-port br-int o-hm0 \
  -- set Interface o-hm0 type=internal \
  -- set Interface o-hm0 external-ids:iface-status=active \
  -- set Interface o-hm0 external-ids:attached-mac=fa:16:3e:07:b3:53 \
  -- set Interface o-hm0 external-ids:skip_cleanup=true \
  -- set Interface o-hm0 external-ids:iface-id=0b180f17-402f-488f-b16c-16a9526e8a46

sudo ip link set dev o-hm0 address fa:16:3e:07:b3:53
sudo dhclient -v o-hm0
```

Thêm các thông tin vào file `/etc/kolla/octavia-worker/octavia.conf`

Chỉnh sửa các tham số `amp_boot_network_list, amp_secgroup_list, amp_flavor_id` và tham số `health_manager` về ip của dải `lb_mgnt` của cả file `/etc/kolla/octavia-health-manager/octavia.conf`

```
[controller_worker]
amp_boot_network_list = 54e69090-760b-4a3e-8af9-1714caf6aa9e
amp_image_tag = amphora
amp_secgroup_list = e4f8988c-0855-46de-b373-37ede8ed28e6
amp_flavor_id = a9ace064-810a-4249-a205-be4d320b0354
amp_ssh_key_name = octavia_ssh_key
client_ca = /etc/octavia/certs/client_ca.cert.pem
network_driver = allowed_address_pairs_driver
compute_driver = compute_nova_driver
amphora_driver = amphora_haproxy_rest_driver
amp_active_retries = 100
amp_active_wait_sec = 2
loadbalancer_topology = SINGLE

[health_manager]
bind_port = 5555
bind_ip = 192.168.199.102
heartbeat_key = insecure
controller_ip_port_list = 192.168.199.102:5555
stats_update_threads = 4
health_update_threads = 4
```

Sau đó ta sẽ restart octavia-worker container

```
docker restart octavia_worker
docker restart octavia_health_manager
```
