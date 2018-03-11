#### Hướng dẫn thực thi script cài đặt OpenStack Newton không có HA

### A. MÔI TRƯỜNG LAB
- Giả lập trên VMware Workstatios, hoặc ESX hoặc Virtualbox hoặc KVM hoặc máy vật lý.
- Ubuntu server 16.04 64 bit

### B. MÔ HÌNH

##### Mô hình tối thiểu
==

![topo-openstack-queens-toithieu.png](/images/queens-images/topo-openstack-queens-toithieu.png)

##### Mô hình đầy đủ
=

![topo-openstack-queens-full.png](/images/queens-images/topo-openstack-queens-full.png)


### C. IP PLANNING


![noha_ip_planning.png](/images/queens-images/IP_Planning_queens.png)


## 1. Các bước thực hiện

### 1.1. Đặt IP theo IP Planning cho từng node.
#### Thực hiện trên Controller1
`Lưu ý:` IP được thiết lập như trong file excel, nếu cần sửa thì sau khi tải script về, sửa trong file `config.cfg`

- Khai báo repos offline nếu muốn sử dụng để tăng tốc độ cài đặt (bỏ qua bước này nếu bạn không có máy chủ repos offline).
	```sh
  echo 'Acquire::http::Proxy "http://172.16.68.18:3142";' >  /etc/apt/apt.conf
  apt-get update -y
  ```
  
- Tải script 
  
  ```sh
  apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
  apt-get -y install git curl vim byobu
  
  git clone https://github.com/congto/openstack-tools.git
  
  mv openstack-tools/scripts/OpenStack-Queens-No-HA/UbuntuScriptsQueens/ /root/queens/
  
  cd queens/  && chmod +x *
  ```
  
- Thực thi script để thiết lập IP và hostname.

  ```sh
  bash ctl_00_setup_ip.sh
  ```
  
Sau khi thực hiện xong, máy chủ sẽ khởi động lại, sử dụng IP `172.16.68.211` để ssh vào và thực hiện theo các bước dưới trên node controller1.

  
#### Thực hiện trên Compute1
`Lưu ý:` IP được thiết lập như trong file excel, nếu cần sửa thì sau khi tải script về, sửa trong file `config.cfg`

- Khai báo repos offline nếu muốn sử dụng để tăng tốc độ cài đặt (bỏ qua bước này nếu bạn không có máy chủ repos offline).
	```sh
  echo 'Acquire::http::Proxy "http://172.16.68.18:3142";' >  /etc/apt/apt.conf
  apt-get update -y
  ```
  
- Tải script 
	```sh
  apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
  apt-get -y install git curl vim byobu
  
  git clone https://github.com/congto/openstack-tools.git
  
  mv openstack-tools/scripts/OpenStack-Queens-No-HA/UbuntuScriptsQueens/ /root/queens/
  
  cd queens/  && chmod +x *
  ```
  
- Thực thi script để thiết lập IP và hostname.

  ```sh
  bash com1_00_setup_ip.sh
  ```
  
Sau khi thực hiện xong, máy chủ sẽ khởi động lại, sử dụng IP `172.16.68.212` để ssh vào và thực hiện theo các bước dưới trên node compute1.
  
#### Thực hiện trên Compute2
`Lưu ý:` IP được thiết lập như trong file excel, nếu cần sửa thì sau khi tải script về, sửa trong file `config.cfg`

- Khai báo repos offline nếu muốn sử dụng để tăng tốc độ cài đặt (bỏ qua bước này nếu bạn không có máy chủ repos offline).
	```sh
  echo 'Acquire::http::Proxy "http://172.16.68.18:3142";' >  /etc/apt/apt.conf
  apt-get update -y
  ```
  
- Tải script 
	```sh
  apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
  apt-get -y install git curl vim byobu
  
  git clone https://github.com/congto/openstack-tools.git
  
  mv openstack-tools/scripts/OpenStack-Queens-No-HA/UbuntuScriptsQueens/ /root/queens/
  
  cd queens/ && chmod +x *
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
  cd /root/queens/
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

- Tới đây có 02 lựa chọn cho việc cài cinder thực hiện script dưới và nhập tùy chọn là `1` hoặc `2` để lựa chọn.

  ```sh
  bash ctl_06_cinder.sh
  ```
  - Nhập 1 để cài cinder-volume cùng với controller, lúc này điều kiện cần là có ổ cứng thứ 2 trên controller để tạo các volume.
  - Nhập 2 để KHÔNG cài cinder-volume, lúc này cinder-volume sẽ được cài ở node khác.

  
- Thực hiện cài đặt horizon

```sh
bash ctl_07_horizon.sh
```

Lúc này có thể truy cập vào địa chỉ: `http://172.16.68.211/horizon` với Domain là `Default`, User là `admin`, mật khẩu là `Vntp2018` (hoặc xem thêm file `/root/admin-openrc` để biết nếu bạn không nhớ). 

### 3. Thực hiện trên Compute1 và Compute2
#### 3.1 Thực hiện trên Compute1

- SSH vào máy chủ có IP 172.16.68.212 với quyền root 
- Thực hiện lệnh dưới để cài các gói môi trường cho `Compute1`

  ```sh
  cd /root/queens/

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
  cd /root/queens/

  bash com2_01_env.sh
  ```

- Cài đặt Neutron và nova 

  ```sh
  bash com2_02_nova_neutron.sh
  ```


### 4. Tạo network, router, flavor, vm

Tơi bước này có 02 lựa chọn tạo các yêu cầu cần thiết để bắt đầu sử dụng OpenStack.

#### 4.1. Tạo network, router, flavor, vm bằng script
Trong bộ script đã có sẵn script để tạo ra các hạ tầng bao gồm: Network, Router, Subnet, Flavor, VM, mở rule .... để sử dụng. Thực hiện script sau:

Đứng trên controller1 và thực hiện các lệnh sau:

```sh
source /root/admin-openrc
```

- Di chuyển vào thư mục chứa script và thực hiện script dưới. Lưu ý thực hiện với quyền root.

  ```sh
  cd UbuntuScriptsQueens

  bash creat_vm.sh
  ```
  
- Truy cập vào horizon với địa chỉ `http://172.16.68.211/horizon` để quan sát tiếp (mật khẩu xem ở file `/root/admin-openrc`

Kết quả ta sẽ có giao diện OpenStack tương tự như hình dưới

![queens-vm-provider01.png](/images/queens-images/queens-vm-provider01.png)


#### 4.2. Tạo network, router, flavor, vm bằng Web

- Truy cập vào horizon với địa chỉ `http://172.16.68.211/horizon` để quan sát tiếp (mật khẩu xem ở file `/root/admin-openrc`


