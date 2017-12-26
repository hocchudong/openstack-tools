# Hướng dẫn triển khai OpenStack sử dụng KOLLA

## Mô hình AIO

### Mô trường
- OS: CentOS 7.4
- NIC1 - eth0 (Dải dùng để dự phòng cho các mục đích khác - dải này không cần ra internet): 
  - IP address 172.16.68.202
  - Subnet mask: 255.255.255.0
  - Gateway: 172.16.68.1
- NIC2 - eth1: dải mạng sử dụng cho API của OpenStack và MNGT Network
  - IP address 172.16.68.202
  - Subnet mask: 255.255.255.0
  - Gateway: 172.16.68.1
- NIC3 - eth2: Đây là dải để cấp public network, dải này VM ra vào internet. Khi đặt IP cho máy cài Kolla thì không cần đặt gateway (gateway dùng cho các VM sau này).
  - IP address 192.168.20.202 
  - Subnet mask: 255.255.255.0
  - Gateway: 192.168.20.1
  
- Mô hình:


### Chuẩn bị

- Đặt hostname

```sh

```


- Đặt IP 

  ```sh

  ```

- Cấu hình cơ bản và và khởi động lại

  ```sh

  ```


### Cài đặt các gói phụ trợ cho kolla

- Cài đặt các gói phụ trợ

  ```sh
  yum install -y epel-release

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

- Thực thi file dưới để thiết lập các khai báo về network, tải image cirros cho hệ thống OpenStack. 

  ```sh
  bash /usr/share/kolla-ansible/init-runonce
  ```
