## Hướng dẫn triển khai OpenStack sử dụng công cụ OpenStack kolla-ansible - mô hình multinode

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

- Gỡ ansible 2.4.2.0 trên CentOS 7.4 64 bit vì không tương thích với phiên bản của kolla 5.0.1 (phiên bản kolla để cài OpenStack Pike)

  ```sh
  pip uninstall -y ansible
  pip install ansible==2.2
  ```
  
- Cài đặt docker trên `deployserver`

  ```sh
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

  yum install -y docker-ce
  ```

- Khở động  và kích hoạt docker.
  ```sh
  systemctl daemon-reload
  systemctl enable docker
  systemctl restart docker
  ```

- Tạo ssh key để sử dụng trong quá trình cài đặt, key này sẽ được copy sang các máy còn lại ở các bước dưới.

  ```sh
  ssh-keygen -t rsa
  ```


#### 4.2.2. Đứng trên các node `controller1`, `compute1` và `compute2` thực hiện các bước sau.

- Cài đặt các gói phụ trợ

  ```sh  
  yum install -y epel-release
  yum update -y
  
  yum install -y git wget gcc python-devel python-pip yum-utils byobu
  ````
  
- Copy ssh key được tạo ra từ node `deployserver`, key này sẽ dùng để node `deployserver` điều khiển các node target thông qua `ansible`

  ```sh

  cd /root

  scp root@172.16.68.200:~/.ssh/id_rsa.pub ./
  ```
  
  - Nhập mật khẩu của node `deployserver`
    ```sh

    cat id_rsa.pub >> ~/.ssh/authorized_keys

    chmod 600 ~/.ssh/authorized_keys
    ```

- Cài đặt các gói phụ trợ và docker trên các node target, trong hướng dẫn này là trên `controller1`, `compute1` và `compute2`
  
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
  
- Khai báo registry cho các host cài docker. Bước này được khai báo để khi các node target tải images thì sẽ tải từ node `deployserver`.
  ```sh
  sed -i "s/\/usr\/bin\/dockerd/\/usr\/bin\/dockerd --insecure-registry 172.16.68.200:4000/g" /usr/lib/systemd/system/docker.service
  ```
 
- Khở động  và kích hoạt docker.
  ```sh
  systemctl daemon-reload
  systemctl enable docker
  systemctl restart docker
  ```
  
  
### 5. Thực hiện deploy kolla

- Đứng trên `deployserver` cấu hình cho docker

- Cấu hình cho docker 
  ```sh
  mkdir /etc/systemd/system/docker.service.d

  tee /etc/systemd/system/docker.service.d/kolla.conf << 'EOF'
  [Service]
  MountFlags=shared
  EOF
  ```

- Tải full images của docker để triển khai các container. Dung lượng khoảng 4GB

  ```sh
  byobu

  cd /root

  wget http://tarballs.openstack.org/kolla/images/centos-source-registry-pike.tar.gz

  ````

- Khai báo đường dẫn của registry local cho node `deployserver`. Lưu ý: Nếu IP của các bạn khác tôi thì cần khai báo lại.
  ```sh
  sed -i "s/\/usr\/bin\/dockerd/\/usr\/bin\/dockerd --insecure-registry 172.16.68.200:4000/g" /usr/lib/systemd/system/docker.service
  ```

- Khởi động lại docker trên node `deployserver` sau khi khai báo đường dẫn của registry server. 
  ```sh
  systemctl daemon-reload
  systemctl restart docker
  ```

  
- Tạo registry local để chứa các images này 

  ```sh
  mkdir /opt/registry

  tar xf centos-source-registry-pike.tar.gz -C /opt/registry
  ```
  
- Tới đây nên tắt máy đi và snapshot lại nếu triển khai trên các máy ảo - mục tiêu là để cài lại nếu có nhu cầu thì việc tải các images và đặt vào registry đã sẵn sàng.

- Tạo container chạy registry. Đây chính là registry local được sử dụng cho toàn bộ các node target.

  ```sh
  docker run -d -p 4000:5000 --restart=always --name registry -v /opt/registry:/var/lib/registry registry
  ```

- Kiểm tra lại xem registry đã hoạt động hay chưa, IP sẽ hiển thị theo thực tế trong lab của bạn.

  ```sh
  curl http://172.16.68.200:4000/v2/lokolla/centos-source-memcached/tags/list
  ```
 
 - Kết quả là: 
 
   ```sh
   {"name":"lokolla/centos-source-memcached","tags":["5.0.1"]}
   ```

### Tải kolla-ansible

- Tải kolla 

  ```sh
  cd /opt

  git clone https://github.com/openstack/kolla-ansible.git -b stable/pike
  
  cd kolla-ansible
  
  pip install -r requirements.txt
  
  python setup.py install
  
  cp -r /usr/share/kolla-ansible/etc_examples/kolla /etc/kolla/
  
  cp /usr/share/kolla-ansible/ansible/inventory/* .
  ```

- Tạo file chứa mật khẩu bằng lệnh dưới, sau khi kết thúc lệnh thì file chứa mật khẩu sẽ nằm tại `/etc/kolla/passwords.yml`

  ```sh
  kolla-genpwd
  ```
  
- Sửa file `/etc/kolla/globals.yml` để khai báo các thành phần cài trong kolla. Lưu ý: IP `172.16.68.202` có thể được thay theo thực tế của môi trường lab mà bạn sử dụng. Trong khai báo này tôi sẽ lựa chọn các project core của OpenStack để triển khai.

  ```sh
  sed -i 's/#kolla_base_distro: "centos"/kolla_base_distro: "centos"/g' /etc/kolla/globals.yml
  sed -i 's/#kolla_install_type: "binary"/kolla_install_type: "source"/g' /etc/kolla/globals.yml
  sed -i 's/#openstack_release: ""/openstack_release: "5.0.1"/g' /etc/kolla/globals.yml
  sed -i 's/kolla_internal_vip_address: "10.10.10.254"/kolla_internal_vip_address: "172.16.68.199"/g' /etc/kolla/globals.yml
  sed -i 's/#docker_registry: "172.16.0.10:4000"/docker_registry: "172.16.68.200:4000"/g' /etc/kolla/globals.yml
  sed -i 's/#docker_namespace: "companyname"/docker_namespace: "lokolla"/g' /etc/kolla/globals.yml
  sed -i 's/#network_interface: "eth0"/network_interface: "eth1"/g' /etc/kolla/globals.yml
  sed -i 's/#neutron_external_interface: "eth1"/neutron_external_interface: "eth2"/g' /etc/kolla/globals.yml
  sed -i 's/#keepalived_virtual_router_id: "51"/keepalived_virtual_router_id: "199"/g' /etc/kolla/globals.yml
  sed -i 's/#enable_haproxy: "yes"/enable_haproxy: "yes"/g' /etc/kolla/globals.yml
  sed -i 's/#nova_compute_virt_type: "kvm"/nova_compute_virt_type: "qemu"/g' /etc/kolla/globals.yml
    ```
 
- Sửa file `/opt/kolla-ansible/multinode` cho phù hợp với mô hình, các dòng cần sửa ở bên dưới. Khai báo này sẽ chỉ ra vai trò của từng node theo mô hình của hướng dẫn, thành phần network sẽ được cài cùng với controller. Lưu ý sửa lại các dòng thừa bằng cách comment, sau khi sửa xong có thể dùng lệnh dưới, lệnh sẽ hiển thị phần đầu như đoạn bên dưới.

  ```sh
  [root@deployserver kolla-ansible]# cat /opt/kolla-ansible/multinode | egrep -v '^#|^$'
  [control]
  172.16.68.201
  [network]
  172.16.68.201
  [compute]
  172.16.68.202
  [monitoring]
  172.16.68.201
  [storage]
  172.16.68.202
  ```

- Thực hiện lệnh dưới để cấu hình cho kolla, lệnh này sẽ truy cập sang các host target để kiểm tra và cài đặt.
  ```sh
  kolla-ansible -i multinode bootstrap-servers
  ```
  - Kết quả: http://prntscr.com/hxgoxq

- Thực hiện lệnh dưới để kiểm tra trước khi deploy kolla

  ```sh
  kolla-ansible prechecks -i multinode
  ```
  - Kết quả: http://prntscr.com/hxgmkm

- Sau khi ok hết, tiếp tục thực hiện lệnh để chính thức deploy openstack, tại bước này node `deployserver` sẽ thực hiện các task của `ansible` được viết trong các playbook và bắt đầu cài lên các máy theo lần lượt.

  ```sh
  kolla-ansible deploy -i multinode
  ```
  
  - Một số hình ảnh về output của màn hình khi thực hiện lệnh trên: 
    - http://prntscr.com/hxgqn9 
    - http://prntscr.com/hxgs8n 
    - http://prntscr.com/hxgsc4 
    - http://prntscr.com/hxgu1z
  
 - Kết quả của lệnh trên cuối cùng sẽ như dưới
    ```sh
    PLAY RECAP *********************************************************************
    172.16.68.201              : ok=190  changed=31   unreachable=0    failed=0
    172.16.68.202              : ok=48   changed=9    unreachable=0    failed=0
    localhost                  : ok=1    changed=0    unreachable=0    failed=0
    ```
    

- Sau khi deploy xong, thực hiện lệnh dưới để kiểm tra trước khi sử dụng
  ```sh
  kolla-ansible post-deploy -i multinode

  ```
 
  - Kết quả: http://prntscr.com/hxijxx
  
- Có thể truy cập vào các node controller1` và `compute1` để kiểm tra các container đã được cài trên từng node bằng lệnh `docker ps -a`. Tham khảo: https://gist.github.com/congto/6a44cf22412ba9101e4b580e2e2c1718

### 6. Sử dụng OpenStack

#### 6.1. Tải các gói bổ trợ cho openstack client trên node `deployserver`
- Cài đặt gói openstack-client để thực thi các lệnh của OpenStack

  ```sh
  pip install python-openstackclient
  ```

- Kiểm tra hoạt động của OpenStack bằng CLI

- Thực thi biến môi trường tại file `/etc/kolla/admin-openrc.sh` (có thể mở ra xem mật khẩu admin để đăng nhập vào horizon)

  ```sh
  source /etc/kolla/admin-openrc.sh
  ```
  
- Thực kiện một số lệnh dưới để kiểm tra hoạt động của OpenStack thông qua CLI

  ```sh
  openstack token issue
  ```

- Các lệnh khác: `openstack project list`, `openstack user list`


### Tạo các khai báo ban đầu sau khi cài OpenStack xong

- Các khai báo ban đề về network, subnet, router, flavor, tải images security .... được khai báo trong script do kolla cung cấp.

- Sửa file /usr/share/kolla-ansible/init-runonce để khai báo network, tạo image ... cho phù hợp với hệ thống của bạn. Trong hướng dẫn này, tôi sẽ sử dụng dải `192.168.20.0/24` để sử dụng cho provider network, dải IP sẽ cấp cho các máy ảo sẽ từ 192.168.20.171 đến 192.168.20.190, dải này trùng với dải của NIC2 (eth2) được khai báo ở trên. Trong thực tế, dải dành cho `provider network` sẽ là IP PUBLIC nhé. Do vậy sửa như bên dưới.

  ```sh
  EXT_NET_CIDR='192.168.20.0/24'
  EXT_NET_RANGE='start=192.168.20.171,end=192.168.20.190'
  EXT_NET_GATEWAY='192.168.20.1'
  ```
  
- Tiếp tục sửa dòng `60` trong file `usr/share/kolla-ansible/init-runonce` để bỏ đoạn `--no-dhcp` để máy ảo có thể gắn trực tiếp vào provider network. Dòng dưới chưa sửa

  ```sh
  openstack subnet create --no-dhcp \
      --allocation-pool ${EXT_NET_RANGE} --network public1 \
      --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} public1-subnet
  ```

- Sau khi sửa, dòng 60 sẽ thành

  ```sh
   openstack subnet create \
      --allocation-pool ${EXT_NET_RANGE} --network public1 \
      --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} public1-subnet
  ```
- Sau khi sửa xong, ta thực hiện.

  ```sh
  bash /usr/share/kolla-ansible/init-runonce
  ```

- Kết quả cuối cùng sẽ hiển thị

  ```sh
  Done.

  To deploy a demo instance, run:

  openstack server create \
      --image cirros \
      --flavor m1.tiny \
      --key-name mykey \
      --nic net-id=48773589-05d2-4667-bb30-1918ec7fd35f \
      demo1

  [root@srv1kolla ~]#
  ````
  
- Tiếp tục thực hiện đoạn lệnh dưới để tạo máy ảo

```sh
openstack server create \
    --image cirros \
    --flavor m1.tiny \
    --key-name mykey \
    --nic net-id=48773589-05d2-4667-bb30-1918ec7fd35f \
    demo1

```

#### 6.2. Truy cập vào dashboad

- Sử dụng IP VIP do đã khai báo ở bước sửa file `global.yml` bên trên, trong hướng dẫn này là 172.16.68.199. Mật khẩu trong file `/etc/kolla/admin-openrc.sh`

