# Hướng dẫn triển khai OpenStack sử dụng KOLLA

## Mô hình AIO

### Mô trường
- OS: CentOS 7.4, RAM: +8GB, HDD: +50GB, CPU: 02
- NIC1 - eth0 (Dải dùng để dự phòng cho các mục đích khác - dải này không cần ra internet): 
  - IP address: 10.10.10.202
  - Subnet mask: 255.255.255.0
- NIC2 - eth1: dải mạng sử dụng cho API của OpenStack và MNGT Network
  - IP address: 172.16.68.202
  - Subnet mask: 255.255.255.0
  - Gateway: 172.16.68.1 (khi cấu hình địa chỉ IP cho máy cài đặt kolla thì sử dụng gateway này)
- NIC3 - eth2: Đây là dải để cấp public network, dải này VM ra vào internet. Khi đặt IP cho máy cài Kolla thì không cần đặt gateway (gateway dùng cho các VM sau này). Trong hướng dẫn này tôi sẽ quy hoạch ip từ 192.168.20.150 tới 192.168.20.170 để cấp cho các máy ảo ở các bước dưới.
  - IP address: 192.168.20.202 
  - Subnet mask: 255.255.255.0
  - Gateway: 192.168.20.1 (Không cần đặt gateway này khi cấu hình cho máy cài đặt kolla.
  
- Mô hình:


### Chuẩn bị

- Đặt hostname

  ```sh
  hostnamectl set-hostname srv1kolla
  ```


- Đặt IP 

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
  ```

- Cấu hình cơ bản và và khởi động lại

  ```sh
  sudo systemctl disable firewalld
  sudo systemctl stop firewalld
  sudo systemctl disable NetworkManager
  sudo systemctl stop NetworkManager
  sudo systemctl enable network
  sudo systemctl start network
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  
  init 6
  ```

### Cài đặt các gói phụ trợ cho kolla

- Cài đặt các gói phụ trợ

  ```sh  
  yum install -y epel-release
  yum update -y
  
  yum install -y git wget ansible gcc python-devel python-pip yum-utils byobu
  ````
 
- Cài đặt docker 

  ```sh
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

  yum install -y docker-ce
  ```

- Tạo thư mục đưới 

  ```sh
  mkdir /etc/systemd/system/docker.service.d
  ```
  
- Khai báo file cấu hình cho kolla 

  ```sh
  tee /etc/systemd/system/docker.service.d/kolla.conf << 'EOF'
  [Service]
  MountFlags=shared
  EOF
  ```

- Khai báo đường dẫn registry cho docker, lưu ý thay IP cho phù hợp với hệ thống của các bạn.

  ```sh
  sed -i "s/\/usr\/bin\/dockerd/\/usr\/bin\/dockerd --insecure-registry 172.16.68.202:4000/g" /usr/lib/systemd/system/docker.service
  ```

- Khởi động và kích hoạt docker 

  ```sh
  systemctl daemon-reload
  systemctl enable docker
  systemctl restart docker
  ```
 
### Tải images pike

- Tải image pike dành cho docker, các image này có dung lượng ~ 4 GB, thời gian lâu hay chậm thì phụ thuộc vào tốc độ mạng. 

  ```sh
  byobu
  
  cd /root
  
  wget http://tarballs.openstack.org/kolla/images/centos-source-registry-pike.tar.gz
  ```

- Tạo registry local để chứa các images này 

  ```sh
  mkdir /opt/registry

  tar xf centos-source-registry-pike.tar.gz -C /opt/registry
  ```
  
- Tới đây nên tắt máy đi và snapshot lại nếu triển khai trên các máy ảo - mục tiêu là để cài lại nếu có nhu cầu thì việc tải các images và đặt vào registry đã sẵn sàng.

- Tạo container chạy registry.

  ```sh
  docker run -d -p 4000:5000 --restart=always --name registry -v /opt/registry:/var/lib/registry registry
  ```

- Kiểm tra lại xem registry đã hoạt động hay chưa, IP sẽ hiển thị theo thực tế trong lab của bạn.

  ```sh
  curl http://172.16.68.202:4000/v2/lokolla/centos-source-memcached/tags/list
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
  
- Cài đặt ansible 2.2 đối với openstack pike 

  ```sh
  pip uninstall -y ansible
  pip install ansible==2.2
  ```
  
- Sửa file `/etc/kolla/globals.yml` để khai báo các thành phần cài trong kolla. Lưu ý: IP `172.16.68.202` có thể được thay theo thực tế của môi trường lab mà bạn sử dụng.

  ```sh
  sed -i 's/#kolla_base_distro: "centos"/kolla_base_distro: "centos"/g' /etc/kolla/globals.yml
  sed -i 's/#kolla_install_type: "binary"/kolla_install_type: "source"/g' /etc/kolla/globals.yml
  sed -i 's/#openstack_release: ""/openstack_release: "5.0.1"/g' /etc/kolla/globals.yml
  sed -i 's/kolla_internal_vip_address: "10.10.10.254"/kolla_internal_vip_address: "172.16.68.202"/g' /etc/kolla/globals.yml
  sed -i 's/#docker_registry: "172.16.0.10:4000"/docker_registry: "172.16.68.202:4000"/g' /etc/kolla/globals.yml
  sed -i 's/#docker_namespace: "companyname"/docker_namespace: "lokolla"/g' /etc/kolla/globals.yml
  sed -i 's/#network_interface: "eth0"/network_interface: "eth1"/g' /etc/kolla/globals.yml
  sed -i 's/#neutron_external_interface: "eth1"/neutron_external_interface: "eth2"/g' /etc/kolla/globals.yml
  sed -i 's/#enable_aodh: "no"/enable_aodh: "yes"/g' /etc/kolla/globals.yml
  sed -i 's/#enable_ceilometer: "no"/enable_ceilometer: "yes"/g' /etc/kolla/globals.yml
  sed -i 's/#enable_gnocchi: "no"/enable_gnocchi: "yes"/g' /etc/kolla/globals.yml
  sed -i 's/#enable_central_logging: "no"/enable_central_logging: "yes"/g' /etc/kolla/globals.yml
  sed -i 's/#enable_grafana: "no"/enable_grafana: "yes"/g' /etc/kolla/globals.yml
  sed -i 's/#enable_haproxy: "yes"/enable_haproxy: "no"/g' /etc/kolla/globals.yml
  sed -i 's/#enable_redis: "no"/enable_redis: "yes"/g' /etc/kolla/globals.yml
  sed -i 's/#nova_compute_virt_type: "kvm"/nova_compute_virt_type: "qemu"/g' /etc/kolla/globals.yml
  ```

- Trong khai báo trên chúng ta đã:
 - Khai báo thêm các thành phần ngoài OpenStack như: grafana để cấu hình tích hợp với gnocchi, bộ ELK để thu thập log.
 - Không khai báo cinder (tức là không có volume).
 
- Việc khai báo này rất linh hoạt, bạn có thể mở file  `/etc/kolla/globals.yml` để xem thêm khai báo khác. 
  
### Cài đặt openstack

- Kiểm tra trước khi cài 

```sh
cd /opt/kolla-ansible/

kolla-ansible prechecks -i all-in-one
```

- Kết quả như sau là ok.

  ```sh
  PLAY RECAP *********************************************************************
  localhost                  : ok=73   changed=0    unreachable=0    failed=0

  [root@compute1 kolla-ansible]#

  ```

- Cài đặt openstack bằng kolla 

  ```sh
  kolla-ansible deploy -i all-in-one
  ```

- Sau khi cài đặt xong ta sẽ có màn hình thông báo kết quả như dưới

  ```sh
  TASK [common : Registering common role has run] ********************************
  skipping: [localhost]

  TASK [skydive : include] *******************************************************
  skipping: [localhost]

  PLAY RECAP *********************************************************************
  localhost                  : ok=313  changed=198  unreachable=0    failed=0
  ```

- Kiểm tra lại sau khi cài đặt xong 

  ```sh
  kolla-ansible post-deploy
  ```

- Kết quả như dưới là ok:

  ```sh
  PLAY [Creating admin openrc file on the deploy node] ***************************

  TASK [setup] *******************************************************************
  ok: [localhost]

  TASK [template] ****************************************************************
  changed: [localhost]

  PLAY RECAP *********************************************************************
  localhost                  : ok=2    changed=1    unreachable=0    failed=0
  ```

### Cấu hình cho OpenStack trước khi sử dụng


- Cài gói OpenStack Client

  ```sh
  pip install python-openstackclient
  ```
  
- Sau khi sửa xong thực thi biến môi trường để sử dụng các lệnh của openstack, có thể mở file `/etc/kolla/admin-openrc.sh` ra xem mật khẩu của tài khoản admin trong OpenStack 
  
  ```sh
  source /etc/kolla/admin-openrc.sh
  ```
  
- Kiểm tra hoạt động của OpenStack bằng lệnh `openstack token issue` sẽ có kết quả như dưới.

  ```sh
  [root@srv1kolla ~]# openstack token issue
  +------------+----------------------------------+
  | Field      | Value                            |
  +------------+----------------------------------+
  | expires    | 2017-12-26T14:46:59+0000         |
  | id         | df158a1058824fc986ae1b6fc01c4a18 |
  | project_id | 600b721c249344d0ac9b96b0536772e1 |
  | user_id    | 49b00a4612864cceb7d6aefd0595fd09 |
  +------------+----------------------------------+
  [root@srv1kolla ~]#
  ```
   
- Sửa file `/usr/share/kolla-ansible/init-runonce` để khai báo network, tạo image ... cho phù hợp với hệ thống của bạn. Trong hướng dẫn này sẽ cấp dải IP của public network từ `192.168.20.150`  đến `192.168.20.170`, dải này trùng với dải của NIC2 (eth2) được khai báo ở trên. Sửa 03 dòng trong file `/usr/share/kolla-ansible/init-runonce` tương ứng với nội dung dưới. 

  ```sh
  EXT_NET_CIDR='192.168.20.0/24'
  EXT_NET_RANGE='start=192.168.20.150,end=192.168.20.170'
  EXT_NET_GATEWAY='192.168.20.1'
  ```

- Tiếp tục sửa file `/usr/share/kolla-ansible/init-runonce`, bỏ tùy chọn `--no-dhcp` trong dòng dưới để có thể gắn máy ảo vào dải provider network, bởi vì khi gắn máy ảo vào dải provider network sẽ cần có dhcp-agent cấp metadata.

```sh
openstack subnet create --no-dhcp \
    --allocation-pool ${EXT_NET_RANGE} --network public1 \
    --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} public1-subnet
```

 - Dòng mới sẽ trở thành 
 
  ```sh
   openstack subnet create \
      --allocation-pool ${EXT_NET_RANGE} --network public1 \
      --subnet-range ${EXT_NET_CIDR} --gateway ${EXT_NET_GATEWAY} public1-subnet
  ```


- Thực thi file dưới để thiết lập các khai báo về network, subnet, router, tải image cirros, tạo keypair, flavor cho hệ thống OpenStack. Trong quá trình thiết lập, màn hình nhắc lệnh để đồng ý tạo keypair, hãy ấn `Enter`

  ```sh
  bash /usr/share/kolla-ansible/init-runonce
  ```
  
- Kết quả sẽ hiển thị thông báo tạo máy ảo.

  ```sh
  Done.

  To deploy a demo instance, run:

  openstack server create \
      --image cirros \
      --flavor m1.tiny \
      --key-name mykey \
      --nic net-id=864371f9-4080-47f3-a6fa-d6e339d4863d \
      demo1
  [root@srv1kolla ~]#
  ```
  
- Thực thi đoạn lệnh dưới để tạo máy ảo.

```sh
openstack server create \
    --image cirros \
    --flavor m1.tiny \
    --key-name mykey \
    --nic net-id=864371f9-4080-47f3-a6fa-d6e339d4863d \
    demo1
```

- Để xem mật khẩu của tài khoản admin trong openstack, xem nội dung file `cat /etc/kolla/admin-openrc.sh`. Sử dụng mật khẩu đó để đăng nhập vào horizon của OpenStack, trong hướng dẫn này là `172.16.68.202`.

- Cần thực hiện floating ip cho máy ảo `demo1` đã tạo ở trên vì chúng ta vừa tạo máy ảo và gắn vào dải mạng selfservice-network, quan sát trong ảnh: http://prntscr.com/hsgb9f

- Ngoài ra bạn còn có thể đăng nhập vào các hệ thống khác mà kolla đã cài đặt. Mật khẩu của các tài khoản này xem tại file `/etc/kolla/passwords.yml`
 - Đăng nhập vào grafana: http://172.16.68.202:3000
 - Đăng nhập vào kibana: http://172.16.68.202:5601
 
- Có thể kiểm tra xem kolla đã tạo các container gì bằng lệnh `docker ps`, việc sử dụng các container này các bạn vọc ở các ghi chép về container khác nhé ;). Kết quả của lênh `docker ps` trong hướng dẫn này là 


  ```sh
  [root@srv1kolla ~]# docker ps
  CONTAINER ID        IMAGE                                                                      COMMAND                  CREATED                                                                                                               STATUS              PORTS                    NAMES
  f58f7a2f6e61        172.16.68.202:4000/lokolla/centos-source-grafana:5.0.1                     "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   grafana
  3f6dab262496        172.16.68.202:4000/lokolla/centos-source-aodh-notifier:5.0.1               "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   aodh_notifier
  9aeb74c41b14        172.16.68.202:4000/lokolla/centos-source-aodh-listener:5.0.1               "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   aodh_listener
  d79d5ffd3c2c        172.16.68.202:4000/lokolla/centos-source-aodh-evaluator:5.0.1              "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   aodh_evaluator
  2ab007ff6ff3        172.16.68.202:4000/lokolla/centos-source-aodh-api:5.0.1                    "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   aodh_api
  4d509b93dba9        172.16.68.202:4000/lokolla/centos-source-ceilometer-compute:5.0.1          "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   ceilometer_compute
  6abba0b0d518        172.16.68.202:4000/lokolla/centos-source-ceilometer-central:5.0.1          "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   ceilometer_central
  a453e23802d6        172.16.68.202:4000/lokolla/centos-source-ceilometer-notification:5.0.1     "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   ceilometer_notification
  e0bf1fa0bdbd        172.16.68.202:4000/lokolla/centos-source-gnocchi-statsd:5.0.1              "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   gnocchi_statsd
  18c0086fce94        172.16.68.202:4000/lokolla/centos-source-gnocchi-metricd:5.0.1             "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   gnocchi_metricd
  1e3f1c9d8c6c        172.16.68.202:4000/lokolla/centos-source-gnocchi-api:5.0.1                 "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   gnocchi_api
  7988691fa1a3        172.16.68.202:4000/lokolla/centos-source-horizon:5.0.1                     "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   horizon
  1b87a029fc66        172.16.68.202:4000/lokolla/centos-source-heat-engine:5.0.1                 "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   heat_engine
  c533f0f5da10        172.16.68.202:4000/lokolla/centos-source-heat-api-cfn:5.0.1                "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   heat_api_cfn
  a27ea03979c8        172.16.68.202:4000/lokolla/centos-source-heat-api:5.0.1                    "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   heat_api
  7f5b3b70a08e        172.16.68.202:4000/lokolla/centos-source-neutron-metadata-agent:5.0.1      "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   neutron_metadata_agent
  3b53f8024015        172.16.68.202:4000/lokolla/centos-source-neutron-l3-agent:5.0.1            "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   neutron_l3_agent
  772cb406d2ee        172.16.68.202:4000/lokolla/centos-source-neutron-dhcp-agent:5.0.1          "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   neutron_dhcp_agent
  21338c2e4caf        172.16.68.202:4000/lokolla/centos-source-neutron-openvswitch-agent:5.0.1   "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   neutron_openvswitch_agent
  2932fea5acfc        172.16.68.202:4000/lokolla/centos-source-neutron-server:5.0.1              "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   neutron_server
  0202d68e0d26        172.16.68.202:4000/lokolla/centos-source-openvswitch-vswitchd:5.0.1        "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   openvswitch_vswitchd
  b9f4f1b8ac0e        172.16.68.202:4000/lokolla/centos-source-openvswitch-db-server:5.0.1       "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   openvswitch_db
  b71947600d8c        172.16.68.202:4000/lokolla/centos-source-nova-compute:5.0.1                "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   nova_compute
  88b6c267cba8        172.16.68.202:4000/lokolla/centos-source-nova-novncproxy:5.0.1             "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   nova_novncproxy
  9e3106edce35        172.16.68.202:4000/lokolla/centos-source-nova-consoleauth:5.0.1            "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   nova_consoleauth
  38c593711c4b        172.16.68.202:4000/lokolla/centos-source-nova-conductor:5.0.1              "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   nova_conductor
  4610ba120faf        172.16.68.202:4000/lokolla/centos-source-nova-scheduler:5.0.1              "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   nova_scheduler
  0b4eb028b13b        172.16.68.202:4000/lokolla/centos-source-nova-api:5.0.1                    "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   nova_api
  0ff40a7c2751        172.16.68.202:4000/lokolla/centos-source-nova-placement-api:5.0.1          "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   placement_api
  00b245ac39e4        172.16.68.202:4000/lokolla/centos-source-nova-libvirt:5.0.1                "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   nova_libvirt
  ae3da3c3bad8        172.16.68.202:4000/lokolla/centos-source-nova-ssh:5.0.1                    "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   nova_ssh
  09dab48a29bc        172.16.68.202:4000/lokolla/centos-source-glance-registry:5.0.1             "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   glance_registry
  2262a29319f0        172.16.68.202:4000/lokolla/centos-source-glance-api:5.0.1                  "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   glance_api
  b1990c3de8c6        172.16.68.202:4000/lokolla/centos-source-keystone:5.0.1                    "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   keystone
  63dc797513c4        172.16.68.202:4000/lokolla/centos-source-rabbitmq:5.0.1                    "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   rabbitmq
  969dde12b96c        172.16.68.202:4000/lokolla/centos-source-mariadb:5.0.1                     "kolla_start"            4 hours ago                                                                                                           Up 4 hours                                   mariadb
  799301efb8f5        172.16.68.202:4000/lokolla/centos-source-memcached:5.0.1                   "kolla_start"            5 hours ago                                                                                                           Up 5 hours                                   memcached
  193a134aabff        172.16.68.202:4000/lokolla/centos-source-kibana:5.0.1                      "kolla_start"            5 hours ago                                                                                                           Up 5 hours                                   kibana
  5668805e3100        172.16.68.202:4000/lokolla/centos-source-redis-sentinel:5.0.1              "kolla_start"            5 hours ago                                                                                                           Up 5 hours                                   redis_sentinel
  f30defa95908        172.16.68.202:4000/lokolla/centos-source-redis:5.0.1                       "kolla_start"            5 hours ago                                                                                                           Up 5 hours                                   redis
  7a35dba775d7        172.16.68.202:4000/lokolla/centos-source-elasticsearch:5.0.1               "kolla_start"            5 hours ago                                                                                                           Up 5 hours                                   elasticsearch
  add07977da7c        172.16.68.202:4000/lokolla/centos-source-cron:5.0.1                        "kolla_start"            5 hours ago                                                                                                           Up 5 hours                                   cron
  5020076f8e63        172.16.68.202:4000/lokolla/centos-source-kolla-toolbox:5.0.1               "kolla_start"            5 hours ago                                                                                                           Up 5 hours                                   kolla_toolbox
  14e76371e77b        172.16.68.202:4000/lokolla/centos-source-fluentd:5.0.1                     "kolla_start"            5 hours ago                                                                                                           Up 5 hours                                   fluentd
  0577297ef94c        registry                                                                   "/entrypoint.sh /e..."   5 hours ago                                                                                                           Up 5 hours          0.0.0.0:4000->5000/tcp   registry
  ```


