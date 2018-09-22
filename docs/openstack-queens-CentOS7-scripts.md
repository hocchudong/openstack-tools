#### Hướng dẫn thực thi script cài đặt OpenStack Rocky không có HA trên CentOS 7

### A. MÔI TRƯỜNG LAB
- Giả lập trên VMware Workstatios, hoặc ESX hoặc Virtualbox hoặc KVM hoặc máy vật lý.
- Centos 7.3 Server 64 bit - 1611

### B. MÔ HÌNH

![noha_openstack_topology.png](/images/noha_openstack_queen_topology.png)

### C. IP PLANNING

![noha_ip_planning.png](/images/noha_openstack_queen_ip_planning.png)



## 1. Các bước thực hiện

### 1.1. Đặt IP theo IP Planning cho từng node.
- Trên Controller thực hiện
	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Queens-No-HA/CentOS7/setup_ip.sh
	bash setup_ip.sh controller1 192.168.70.120 192.168.82.120 192.168.81.120 192.168.84.120
	```

- Trên Compute1 thực hiện
	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Queens-No-HA/CentOS7/setup_ip.sh
	bash setup_ip.sh compute1 192.168.70.121 192.168.82.121 192.168.81.121 192.168.84.121
	```

- Trên Compute2 thực hiện

	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Queens-No-HA/CentOS7/setup_ip.sh
	bash setup_ip.sh compute2 192.168.70.122 192.168.82.122 192.168.81.122 192.168.84.122
	```

- Thực hiện trên máy Cinder

	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Queens-No-HA/CentOS7/setup_ip.sh
	bash setup_ip.sh cinder1 192.168.70.123 192.168.82.123 192.168.81.123 192.168.84.123
	```

	
## Thực hiện script cài đặt OpenStack
### 2. Thực hiện cài đặt trên Controller
#### 2.1. Tải script 
- Đứng trên node CTL1 và thực hiện các bước dưới.
- Chuyển sang quyền root
	```sh
	su -
	```
	
- Cài đặt git và script cài đặt.
	```sh
	yum -y install git
	git clone https://github.com/congto/openstack-tools.git

	mv openstack-tools/scripts/OpenStack-Queens-No-HA/CentOS7 /root/

	cd CentOS7
	chmod +x *.sh
	```

- Nếu muốn sửa các IP thì sử dụng VI hoặc VIM để sửa, cần lưu ý tên NICs và địa chỉ IP cần phải tương ứng (trong này này tên NICs là ens160, ens192, ens224, ens256)


-  Nếu cần thiết thì cài ứng dụng `byobu` để khi các phiên ssh bị mất kết nối thì có thể sử dụng lại (để sử đụng lại thì cần ssh vào và gõ lại lệnh `byobu`)

	```sh
	sudo yum -y install epel-release
	sudo yum -y install byobu
	```

- Gõ lệnh byobu

	```sh
	byobu
	```

#### 2.2. Thực thi script `noha_ctl_prepare.sh`

- Lưu ý, lúc này cửa sổ nhắc lệnh đang ở thư mục `/root/CentOS7/` của node CTL1

- Thực thi script  `noha_ctl_prepare.sh`

	```sh
	bash noha_ctl_prepare.sh
	```

- Trong quá trình chạy script, cần nhập password cho tài khoản root của máy COM1 và COM2


#### 2.3. Thực thi script `noha_ctl_install_db_rabbitmq.sh` để cài đặt DB và các gói bổ trợ.
- Sau khi node CTL khởi động lại, đăng nhập bằng quyền root và thực thi các lệnh dưới.

	```sh
	cd /root/CentOS7/

	bash noha_ctl_install_db_rabbitmq.sh
	```

#### 2.4. Thực thi script `noha_ctl_keystone.sh` để cài đặt `Keystone`.

- Thực thi script bằng lệnh dưới.
	```sh
	bash noha_ctl_keystone.sh
	```

- Sau khi cài đặt xong keystone, script sẽ tạo ra 2 file source `admin-openrc` và `demo-openrc` nằm ở thư mục root. Các file này chứa biến môi trường để làm việc với OpenStack. Thực hiện lệnh dưới để có thể tương tác với OpenStack bằng CLI.

	```sh
	source /root/admin-openrc
	```

- Kiểm tra lại xem đã thao tác được với OpenStack bằng CLI hay chưa bằng lệnh

	```sh
	openstack token issue
	```

	- Kết quả là:
		```sh
		+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
		| Field      | Value                                                                                                                                                                                   |
		+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
		| expires    | 2017-07-18 16:35:00+00:00                                                                                                                                                               |
		| id         | gAAAAABZbiqkN6mxVSttOCHdbPgCFAHmdlvdfHUpf2MrV_1nwq_ZrXGNJEdT-e7HInzxF8puHMG0-dnwe-NqRMvMDn_-lpYTX7m5G-oIpw4nWX0B9orECIYN4DXfUa07tg6pyo8-Zi7yte9uxqH54S1LYgdlk-GyX9130JESn3I_cw63b_9Rz-s |
		| project_id | 023aabfb532f4974a07923f1b48f1e2a                                                                                                                                                        |
		| user_id    | 3b79c537783f409e9cc28d6cef6ad393                                                                                                                                                        |
		+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
		[root@ctl1 noha]#
		```

#### 2.5. Thực thi script `noha_ctl_glance.sh` để cài đặt `Glance`.

- Thực thi script dưới để cài đặt Glance.

	```sh
	bash noha_ctl_glance.sh
	```
	
#### 2.6. Thực thi script `noha_ctl_nova.sh.sh` để cài đặt `Nova`.

- Thực thi script dưới để cài đặt Nova.

	```sh
	bash noha_ctl_nova.sh
	```
	
- Sau khi script thực thi xong, kiểm tra xem nova đã cài đặt thành công trên Controller bằng lệnh dưới.
	```sh
	openstack compute service list
	```

- Kết quả như sau là đã hoàn tất việc cài nova trên controller
	```sh
	+----+------------------+------+----------+---------+-------+----------------------------+
	| ID | Binary           | Host | Zone     | Status  | State | Updated At                 |
	+----+------------------+------+----------+---------+-------+----------------------------+
	|  3 | nova-consoleauth | ctl1 | internal | enabled | up    | 2017-07-18T15:46:34.000000 |
	|  4 | nova-scheduler   | ctl1 | internal | enabled | up    | 2017-07-18T15:46:37.000000 |
	|  5 | nova-conductor   | ctl1 | internal | enabled | up    | 2017-07-18T15:46:31.000000 |
	+----+------------------+------+----------+---------+-------+----------------------------+
	```

#### 2.7. Thực thi script `noha_ctl_neutron.sh` để cài đặt `Neutron`.

- Thực thi script dưới để cài đặt Neutron.

	```sh
	bash noha_ctl_neutron.sh
	```
	
#### 2.8. Thực thi script `noha_ctl_cinder.sh` để cài đặt `Cinder`.

- Thực thi script dưới để cài đặt Cinder trên node controller. Tới đây có 2 lựa chọn.

##### 2.8.1. Lựa chọn 1: 
- Cài tất cả các thành phần cinder trên node controller
- Lưu ý: Đối với lựa chọn này, máy Controller cần có 02 ổ cứng, ổ thứ nhất để cài OS, ổ thứ 2 (sdb hoặc vdb) dùng để tạo các LVM để Cinder sử dụng sau này.

	```sh
	bash noha_ctl_cinder.sh aio
	```

- Lúc này không cần thực thi trên node `cinder1` nữa bởi vì cinder-volume được cài trên node `controller1`. Bỏ qua việc cài đặt trên node cinder.
	
##### 2.8.2 Lựa chọn 2:
- Lựa chọn này áp dụng cho mô hình tách node cinder-volume riêng và không nằm trên cùng trên cùng controller.
- Lúc này, trên controller chỉ có `cinder-api, cinder-scheduler`. Trên node cinder cài `cinder-volume`. Ta sẽ không đưa keywword `aio` 
	```sh
	bash noha_ctl_cinder.sh
	```

- Nếu chọn lựa chọn 2 thì cần cài đặt thêm các bước ở node cinder bên dưới, mục số 5.

		
#### 2.9. Thực thi script `noha_ctl_horizon.sh` để cài đặt Dashboad.
- Cài đặt dashboad để cung cấp giao diện cho OpenStack.
	```sh
	bash noha_ctl_horizon.sh
	```
		
	
### 3. Thực hiện cài đặt trên Compute1 và Compute2 (cài Nova và Neutron)

#### 3.1. Cài đặt Nova và neutron trên Compute1 và Compute2

- Login vào máy Compute1, kiểm tra xem đã có file `config.cfg` trong thư mục root hay chưa. File này được copy khi thực hiện script đầu tiên ở trên node Controller. Nếu chưa có thì copy từ Controller sang. Nếu có rồi thì thực hiện bước dưới.
- Tải script cài đặt nova và neutron cho Compute1

	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Queens-No-HA/CentOS7/noha_com_install.sh
	
	bash noha_com_install.sh
	```

- Lưu ý: bước này thực hiện trên cả 02 Compute1 và Compute2

### Kiểm tra lại xem Nova và Neutron 

- Để kiểm tra Nova và Neutron đã được cài thành công trên 2 node Compute1 và Compute2 hay chưa bằng các lệnh dưới.

- Đứng trên Controller thực hiện lệnh kiểm tra các agent của neutron. 
	```sh
	[root@ctl1 ~]# openstack network agent list
	```

	- Kết quả nhu dưới
	
		```sh
		+--------------------------------------+--------------------+------+-------------------+-------+-------+---------------------------+
		| ID                                   | Agent Type         | Host | Availability Zone | Alive | State | Binary                    |
		+--------------------------------------+--------------------+------+-------------------+-------+-------+---------------------------+
		| 1dbe7df1-feee-4f28-91ac-a19ed2ca0491 | Metadata agent     | com2 | None              | True  | UP    | neutron-metadata-agent    |
		| 560459e5-15ed-4cbf-a360-022a764fc642 | Metadata agent     | com1 | None              | True  | UP    | neutron-metadata-agent    |
		| 9d7f31c9-b5a8-4d36-bafb-940b8cacf2fa | Linux bridge agent | com2 | None              | True  | UP    | neutron-linuxbridge-agent |
		| a3402985-7b73-4090-b039-54186aa6642e | DHCP agent         | com1 | nova              | True  | UP    | neutron-dhcp-agent        |
		| d4f3b500-7865-40d7-ad6f-cf7c05284604 | DHCP agent         | com2 | nova              | True  | UP    | neutron-dhcp-agent        |
		| e26be4a6-ffa1-448f-9c1d-7b13de6ebea3 | Linux bridge agent | com1 | None              | True  | UP    | neutron-linuxbridge-agent |
		+--------------------------------------+--------------------+------+-------------------+-------+-------+---------------------------+
		```

- Đứng trên Controller thực hiện lệnh kiểm tra service của nova 
	```sh
	openstack compute service list
	```

	- Kết quả là: 
	
		```
		+----+------------------+------+----------+---------+-------+----------------------------+
		| ID | Binary           | Host | Zone     | Status  | State | Updated At                 |
		+----+------------------+------+----------+---------+-------+----------------------------+
		|  3 | nova-consoleauth | ctl1 | internal | enabled | up    | 2017-07-18T16:31:09.000000 |
		|  4 | nova-scheduler   | ctl1 | internal | enabled | up    | 2017-07-18T16:31:09.000000 |
		|  5 | nova-conductor   | ctl1 | internal | enabled | up    | 2017-07-18T16:31:08.000000 |
		|  6 | nova-compute     | com1 | nova     | enabled | up    | 2017-07-18T16:31:04.000000 |
		|  7 | nova-compute     | com2 | nova     | enabled | up    | 2017-07-18T16:31:14.000000 |
		+----+------------------+------+----------+---------+-------+----------------------------+
		```

### 4. Tạo network  và các máy ảo để kiểm chứng. 

#### 4.1. Tạo provider network và subnet thuộc provider network

- Tạo provider network. Lưu ID của network này để cung cấp khi tạo máy ảo.

	```sh
	openstack network create  --share --external \
	--provider-physical-network provider \
	--provider-network-type flat provider
	```
	
	- Giả sửa ID của network là `9681d9dd-aae2-42fe-9b84-dd7cb04c1aca`
	
- Tạo subnet thuộc provider network. Lưu ý nhập đúng gateway, IP cấp cho máy ảo từ 200 tới 220.

	```sh
	openstack subnet create subnet1_provider --network provider \
	 --allocation-pool start=192.168.84.130,end=192.168.84.148 \
	 --dns-nameserver 8.8.8.8 --gateway 192.168.84.1 \
	 --subnet-range 192.168.84.0/24
	```

#### 4.2. Tạo flavor

- Tạo flavor

	```sh
	openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
	openstack flavor create --id 1 --vcpus 1 --ram 1024 --disk 20 m1.tiny
	openstack flavor create --id 2 --vcpus 2 --ram 2408 --disk 40 m1.small
	```

#### 4.3. Mở các rule 

- Khai báo các rule cho phép ping và ssh tới máy ảo. 
	```sh
	openstack security group rule create --proto icmp default
	openstack security group rule create --proto tcp --dst-port 22 default
	```
	
#### 4.4. Tạo máy ảo

- Tạo máy ảo cần cung cấp các ID hoặc tên về images, network, flavor. Giả sử ID của network đã có, images là `cirros`, flavor có tên là `m1.nano`

	```sh
	openstack server create Provider_VM01 --flavor m1.nano --image cirros \
		--nic net-id=9681d9dd-aae2-42fe-9b84-dd7cb04c1aca --security-group default
	```
	
- Chờ một lát, máy ảo sẽ được tạo, sau đó kiểm tra bằng lệnh dưới, ta sẽ thấy thông tin máy ảo và IP

	```sh
	openstack server list
	```

- Lúc này có thể ping và ssh tới máy ảo bằng tài khoản `cirros` và mật khẩu là `cubswin:)` . Minh họa http://prntscr.com/fznbcb



### 5. Cài đặt trên Cinder node
- Lựa chọn này sử dụng khi cinder-volume và cinder-backup nằm trên một máy chủ riêng. 

#### 5.1. Đặt hostname và IP

- Login vào máy chủ cinder và thực thi script dưới và khai báo các tham số về hostname và IP của các NICs.
	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Rocky-No-HA/setup_ip.sh

	bash setup_ip.sh cinder1 192.168.20.36 10.10.0.36 172.16.20.36 192.168.40.36
	```

#### 5.2. Cài đặt các gói bổ trợ cho Cinder node. 
- Lưu ý: Đứng trên controller node, thực hiện script cài đặt các gói bổ trợ cho máy chủ Cinder trước khi cài.
- Thực thi script dưới và chỉ ra  IP của máy chủ Cinder, trong hướng dẫn này là 192.168.20.36. Sau khi thực hiện script, bạn cần nhập mật khẩu của máy chủ Cinder
	```sh
	bash noha_node_prepare.sh 192.168.20.36
	```

#### 5.3. Thực thi script cài đặt cinder trên máy chủ cinder

- Login vào máy chủ cinder và thực hiện script dưới tại thư mục root. Lưu ý, ở script trên đã copy file `config.cfg` từ máy chủ controller sang máy chủ cinder. 
	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Rocky-No-HA/noha_cinder_install.sh

	bash noha_cinder_install.sh
	```

- Sau khi cài đặt xong trên máy chủ cinder, quay lại máy chủ controller kiểm tra xem cinder đã hoạt động hay chưa bằng lệnh.
	```sh
	openstack volume service list
	```
	
	- Kết quả là các service của cinder sẽ hiển thị, việc `cinder-volume` tại controller node bị down là do ta không dùng `cinder-volume` không kích hoạt trên máy chủ cinder.
	
		```sh
		+------------------+-------------+------+---------+-------+----------------------------+
		| Binary           | Host        | Zone | Status  | State | Updated At                 |
		+------------------+-------------+------+---------+-------+----------------------------+
		| cinder-backup    | controller1 | nova | enabled | up    | 2017-07-26T14:21:38.000000 |
		| cinder-scheduler | controller1 | nova | enabled | up    | 2017-07-26T14:21:31.000000 |
		| cinder-volume    | controller1 | nova | enabled | down  | 2017-07-26T09:22:34.000000 |
		| cinder-volume    | cinder1@lvm | nova | enabled | up    | 2017-07-26T14:21:31.000000 |
		+------------------+-------------+------+---------+-------+----------------------------+
		```
		

