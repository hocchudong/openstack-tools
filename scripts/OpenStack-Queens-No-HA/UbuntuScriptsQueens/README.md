#### Hướng dẫn thực thi script cài đặt OpenStack Newton không có HA

### A. MÔI TRƯỜNG LAB
- Giả lập trên VMware Workstatios, hoặc ESX hoặc Virtualbox hoặc KVM hoặc máy vật lý.
- Centos 7.3 Server 64 bit - 1611

### B. MÔ HÌNH

![noha_openstack_topology.png](/images/openstack-queen-topo.png)

### C. IP PLANNING

![noha_ip_planning.png](/images/IP_Planning_queens.png)



## 1. Các bước thực hiện

### 1.1. Đặt IP theo IP Planning cho từng node.
#### Thực hiện trên Controller1
`Lưu ý:` IP được thiết lập như trong file excel, nếu cần sửa thì sau khi tải script về, sửa trong file `config.cfg`
- Tải script 
	```sh
  echo 'Acquire::http::Proxy "http://172.16.68.18:3142";' >  /etc/apt/apt.conf

  apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
  apt-get -y install git curl vim byobu
  
  git clone https://github.com/congto/openstack-tools.git
  
  mv openstack-tools/scripts/OpenStack-Queens-No-HA/UbuntuScriptsQueens/ .
  cd UbuntuScriptsQueens/
	chmod +x *
  ```
  
- Thực thi script để thiết lập IP và hostname.

  ```sh
  bash ctl_00_setup_ip.sh
  ```
  
Sau khi thực hiện xong, máy chủ sẽ khởi động lại, sử dụng IP `172.16.68.211` để ssh vào và thực hiện theo các bước dưới trên node controller1.

  
#### Thực hiện trên Compute1
`Lưu ý:` IP được thiết lập như trong file excel, nếu cần sửa thì sau khi tải script về, sửa trong file `config.cfg`

- Tải script 
	```sh
  echo 'Acquire::http::Proxy "http://172.16.68.18:3142";' >  /etc/apt/apt.conf
  
  apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
  apt-get -y install git curl vim byobu
  
  git clone https://github.com/congto/openstack-tools.git
  
  mv openstack-tools/scripts/OpenStack-Queens-No-HA/UbuntuScriptsQueens/ .
  cd UbuntuScriptsQueens/
	chmod +x *
  ```
  
- Thực thi script để thiết lập IP và hostname.

  ```sh
  bash com1_00_setup_ip.sh
  ```
  
Sau khi thực hiện xong, máy chủ sẽ khởi động lại, sử dụng IP `172.16.68.212` để ssh vào và thực hiện theo các bước dưới trên node compute1.
  
#### Thực hiện trên Compute2
`Lưu ý:` IP được thiết lập như trong file excel, nếu cần sửa thì sau khi tải script về, sửa trong file `config.cfg`
- Tải script 
	```sh
  echo 'Acquire::http::Proxy "http://172.16.68.18:3142";' >  /etc/apt/apt.conf
  apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
  apt-get -y install git curl vim byobu
  
  git clone https://github.com/congto/openstack-tools.git
  
  mv openstack-tools/scripts/OpenStack-Queens-No-HA/UbuntuScriptsQueens/ .
  cd UbuntuScriptsQueens/
	chmod +x *
  ```
  
- Thực thi script để thiết lập IP và hostname.

  ```sh
  bash com2_00_setup_ip.sh
  ```
  
Sau khi thực hiện xong, máy chủ sẽ khởi động lại, sử dụng IP `172.16.68.213` để ssh vào và thực hiện theo các bước dưới trên node compute2.
	
## Thực hiện script cài đặt OpenStack
### 2. Thực hiện cài đặt trên Controller
#### 2.1. Thực thi các script cài đặt trên controller1

- Đứng trên node CTL1 và thực hiện các bước dưới.
- Đăng nhập sau đó chuyển sang quyền root
	```sh
	su -
	```
	
- Cài đặt git và script cài đặt.
	```sh
  cd UbuntuScriptsQueens
	```

- Thực thi script cài đặt các gói bổ trợ trên node controller1

  ```sh
  bash ctl_01_env.sh
  ```

- Thực thi script cài đặt keystone trên controller1

  ```sh
  bash ctl_02_keystone.sh
  ```

Sau khi chạy xong script cài đặt keystone, script sẽ sinh ra các file tại `/root/admin-openrc` dùng để xác thực với OpenStack, sử dụng lệnh dưới mỗi khi thao tác với openstack thông qua CLI.

  ```sh
  source /root/admin-openrc
  ```
  
- Thực thi script cài đặt glance trên controller1

  ```sh
  bash ctl_03_glance.sh
  ```
  
- Thực thi script cài đặt nova trên controller1

  ```sh
  bash ctl_04_nova.sh
  ```


- Thực thi script cài đặt neutron trên controller1

  ```sh
  bash ctl_05_neutron.sh
  ```

  
- Thực hiện cài đặt horizon

```sh
bash ctl_06_horizon.sh
```

Lúc này có thể truy cập vào địa chỉ: `http://172.16.68.211/horizon` với Domain là `Default`, User là `admin`, mật khẩu là `Vntp2018` (hoặc xem thêm file `/root/admin-openrc` để biết nếu bạn không nhớ). 

### 3. Thực hiện trên Compute1 và Compute2
#### 3.1 Thực hiện trên Compute1

- SSH vào máy chủ có IP 172.16.68.212 với quyền root 
- Thực hiện lệnh dưới để cài các gói môi trường cho `Compute1`

  ```sh
  cd UbuntuScriptsQueens

  bash com1_01_env.sh
  ```

- Cài đặt Neutron và nova 

  ```sh
  bash com1_02_nova_neutron.sh
  ```

#### 3.1 Thực hiện trên Compute2

- SSH vào máy chủ có IP 172.16.68.213 với quyền root 
- Thực hiện lệnh dưới để cài các gói môi trường cho `Compute2`

  ```sh
  cd UbuntuScriptsQueens

  bash com2_01_env.sh
  ```

- Cài đặt Neutron và nova 

  ```sh
  bash com2_02_nova_neutron.sh
  ```


### Tạo network, router, vm