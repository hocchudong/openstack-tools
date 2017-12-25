# Hướng dẫn triển khai OpenStack sử dụng KOLLA

## Mô hình AIO

### Mô trường
- OS: CentOS 7.4
- NIC1 (API + MNGT Network): IP address 172.16.68.202, subnetmask: 255.255.255.0, gateway: 172.16.68.1
- NIC2 (Public network): IP address 192.168.20.202 / 24, gateway: 192.168.20.1
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

- Khai báo đường dẫn registry cho docker 

  ```sh
  sed -i "s/\/usr\/bin\/dockerd/\/usr\/bin/dockerd --insecure-registry 172.16.68.202:4000/g" /usr/lib/systemd/system/docker.service
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
  cd /root
  wget http://tarballs.openstack.org/kolla/images/centos-source-registry-pike.tar.gz
  ```

- Tạo registry local để chứa các images này 

  ```sh
  mkdir /opt/registry

  tar xf centos-source-registry-pike.tar.gz -C /opt/registry

  docker run -d -p 4000:5000 --restart=always --name registry -v /opt/registry:/var/lib/registry registry
  ```

- Kiểm tra lại xem registry đã hoạt động hay chưa

  ```sh
  curl http://192.168.0.159:4000/v2/lokolla/centos-source-memcached/tags/list
  ```
 
 - Kết quả là: 
 
   ```sh
   {"name":"lokolla/centos-source-memcached","tags":["5.0.1"]}
   ```