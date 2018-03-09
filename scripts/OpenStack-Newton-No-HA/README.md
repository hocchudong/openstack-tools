## Thư mục chứa script cài đặt Newton
- Hướng dẫn được tập hợp tại thư mục docs.#### Hướng dẫn thực thi script cài đặt OpenStack Newton không có HA

### A. MÔI TRƯỜNG LAB
- Giả lập trên VMware Workstatios, hoặc ESX hoặc Virtualbox hoặc KVM hoặc máy vật lý.
- Centos 7.3 Server 64 bit - 1611

### B. MÔ HÌNH

![noha_openstack_topology.png](/images/noha_openstack_topology.png)

### C. IP PLANNING

![noha_ip_planning.png](/images/noha_ip_planning.png)



## 1. Các bước thực hiện

### 1.1. Đặt IP theo IP Planning cho từng node.
- Trên Controller thực hiện
	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Newton-No-HA/setup_ip.sh
	bash setup_ip.sh controller1 192.168.20.33 10.10.0.33 172.16.20.33 192.168.40.33
	```

- Trên Compute1 thực hiện
	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Newton-No-HA/setup_ip.sh
	bash setup_ip.sh compute1 192.168.20.34 10.10.0.34 172.16.20.34 192.168.40.34
	```

- Trên Compute2 thực hiện

	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Newton-No-HA/setup_ip.sh
	bash setup_ip.sh compute2 192.168.20.35 10.10.0.35 172.16.20.35 192.168.40.35
	```

- Thực hiện trên máy Cinder

	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Newton-No-HA/setup_ip.sh

	bash setup_ip.sh cinder1 192.168.20.36 10.10.0.36 172.16.20.36 192.168.40.36
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

	mv openstack-tools/scripts/OpenStack-Newton-No-HA /root/

	cd OpenStack-Newton-No-HA
	chmod +x *.sh
	```

- Nếu muốn sửa các IP thì sử dụng VI hoặc VIM để sửa, cần lưu ý tên NICs và địa chỉ IP cần phải tương ứng (trong này này tên NICs là ens160, ens192, ens224, ens256)

- Trong toàn bộ quá trình chạy script, chỉ cần thực hiện trên node CTL1, script sẽ tự động cài đặt các node còn lại. Do vậy cần phải ping được từ node CTL1 tới COM1 và COM2 để đảm bảo CTL1 có thể tạo ssh keygen cho COM1 và COM2.

	```sh
	ping -c 3 192.168.20.34 
	
	ping -c 3 192.168.20.35
	```

-  Nếu cần thiết thì cài ứng dụng `byobu` để khi các phiên ssh bị mất kết nối thì có thể sử dụng lại (để sử đụng lại thì cần ssh vào và gõ lại lệnh `byobu`)

	```sh
	sudo yum install epel-release -y
	sudo yum install byobu -y --enablerepo=epel-testing
	```

- Gõ lệnh byobu

	```sh
	byobu
	```

#### 2.2. Thực thi script `noha_ctl_prepare.sh`

- Lưu ý, lúc này cửa sổ nhắc lệnh đang ở thư mục `/root/OpenStack-Newton-No-HA/` của node CTL1

- Thực thi script  `noha_ctl_prepare.sh`

	```sh
	bash noha_ctl_prepare.sh
	```

- Trong quá trình chạy script, cần nhập password cho tài khoản root của máy COM1 và COM2


#### 2.3. Thực thi script `noha_ctl_install_db_rabbitmq.sh` để cài đặt DB và các gói bổ trợ.
- Sau khi node CTL khởi động lại, đăng nhập bằng quyền root và thực thi các lệnh dưới.

	```sh
	cd /root/OpenStack-Newton-No-HA/

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
	
- Sau khi cài neutron trên node Controller xong, thực hiện các lệnh dưới để kiểm tra
	
	- Kiểm tra các agent của neutron sau khi cài, trong script này trên controller chỉ cài neutron server, các agent của neutron được cài trên các node Compute. Kết quả của lệnh dưới sẽ là rỗng.
		```sh
		openstack network agent list
		```
	
	- Kiểm tra các extention của neutron
		```sh
		neutron ext-list
		```
	
		- Kết quả lệnh trên như dưới
			```sh
			+---------------------------+-----------------------------------------------+
			| alias                     | name                                          |
			+---------------------------+-----------------------------------------------+
			| default-subnetpools       | Default Subnetpools                           |
			| network-ip-availability   | Network IP Availability                       |
			| network_availability_zone | Network Availability Zone                     |
			| auto-allocated-topology   | Auto Allocated Topology Services              |
			| ext-gw-mode               | Neutron L3 Configurable external gateway mode |
			| binding                   | Port Binding                                  |
			| agent                     | agent                                         |
			| subnet_allocation         | Subnet Allocation                             |
			| l3_agent_scheduler        | L3 Agent Scheduler                            |
			| tag                       | Tag support                                   |
			| external-net              | Neutron external network                      |
			| flavors                   | Neutron Service Flavors                       |
			| net-mtu                   | Network MTU                                   |
			| availability_zone         | Availability Zone                             |
			| quotas                    | Quota management support                      |
			| l3-ha                     | HA Router extension                           |
			| provider                  | Provider Network                              |
			| multi-provider            | Multi Provider Network                        |
			| address-scope             | Address scope                                 |
			| extraroute                | Neutron Extra Route                           |
			| subnet-service-types      | Subnet service types                          |
			| standard-attr-timestamp   | Resource timestamps                           |
			| service-type              | Neutron Service Type Management               |
			| l3-flavors                | Router Flavor Extension                       |
			| port-security             | Port Security                                 |
			| extra_dhcp_opt            | Neutron Extra DHCP opts                       |
			| standard-attr-revisions   | Resource revision numbers                     |
			| pagination                | Pagination support                            |
			| sorting                   | Sorting support                               |
			| security-group            | security-group                                |
			| dhcp_agent_scheduler      | DHCP Agent Scheduler                          |
			| router_availability_zone  | Router Availability Zone                      |
			| rbac-policies             | RBAC Policies                                 |
			| standard-attr-description | standard-attr-description                     |
			| router                    | Neutron L3 Router                             |
			| allowed-address-pairs     | Allowed Address Pairs                         |
			| project-id                | project_id field enabled                      |
			| dvr                       | Distributed Virtual Router                    |
			+---------------------------+-----------------------------------------------+
			```

#### 2.8. Thực thi script `noha_ctl_cinder.sh` để cài đặt `Cinder`.

- Thực thi script dưới để cài đặt Cinder trên node controller. Tới đây có 2 lựa chọn.

##### 2.8.1. Lựa chọn 1: 
- Cài tất cả các thành phần cinder trên node controller
- Lưu ý: Máy CTL có 02 ổ cứng, ổ thứ nhất để cài OS, ổ thứ 2 (sdb hoặc vdb) dùng để tạo các LVM để Cinder sử dụng sau này.

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

#### 2.9. Thực thi script `noha_ctl_ceilometer.sh` để cài đặt `Ceilometer, Gnocchi, AODH`.
- Thực thi script cài đặt Ceilometer, Gnocchi, AODH
	```sh
	bash noha_ctl_ceilometer.sh
	```
	- Sau khi cài đặt xong, thực hiện các lệnh dưới để kiểm tra hoạt động của ceilometer, gnocchi, aodh. Có thể các lệnh sẽ không có output ra.
		
		```sh
		gnocchi resource list HOẶC openstack metric resource list 
		gnocchi metric list HOẶC openstack metric metric list 
		
		aodh alarm list
		```

- Khi chạy các lệnh `gnocchi metric list` HOẶC `openstack metric metric list ` thì output như dưới:
	```sh
	+--------------------------------------+---------------------+----------------+------+--------------------------------------+
	| id                                   | archive_policy/name | name           | unit | resource_id                          |
	+--------------------------------------+---------------------+----------------+------+--------------------------------------+
	| ac177241-405b-4028-a72d-6084c43552e6 | low                 | image.size     | B    | 7cef7f8a-24ef-48a0-95de-0a6908b0c8c9 |
	| db267fbe-bbb7-4c3f-952f-aa5869c57127 | low                 | image.download | None | 7cef7f8a-24ef-48a0-95de-0a6908b0c8c9 |
	| e9df3db9-87bb-472b-8ac4-f7fa4b3782f6 | low                 | image.serve    | None | 7cef7f8a-24ef-48a0-95de-0a6908b0c8c9 |
	| f37af4ec-8f20-4558-89ce-aeaa3402c931 | low                 | image          | None | 7cef7f8a-24ef-48a0-95de-0a6908b0c8c9 |
	+--------------------------------------+---------------------+----------------+------+--------------------------------------+
	```

- Khi chạy các lệnh `gnocchi resource list` HOẶC `openstack metric resource list` thì output như dưới:
	```sh
	+---------------------------+-------+---------------------------+---------+---------------------------+---------------------------+----------+------------------------------+--------------+
	| id                        | type  | project_id                | user_id | original_resource_id      | started_at                | ended_at | revision_start               | revision_end |
	+---------------------------+-------+---------------------------+---------+---------------------------+---------------------------+----------+------------------------------+--------------+
	| 7cef7f8a-24ef-48a0-95de-  | image | 428c840991bb426baa82e4e45 | None    | 7cef7f8a-24ef-48a0-95de-  | 2017-08-14T08:37:47.35056 | None     | 2017-08-14T08:37:47.350581+0 | None         |
	| 0a6908b0c8c9              |       | 728809d                   |         | 0a6908b0c8c9              | 0+00:00                   |          | 0:00                         |              |
	+---------------------------+-------+---------------------------+---------+---------------------------+---------------------------+----------+------------------------------+--------------+
	[
	```

- Do gnocchi client được thay thế bởi tập lệnh openstack client nên kết quả các lệnh là giống nhau. Có thể trong các phiên bản OpenStack khác OpenStack Newton thì câu lệnh sẽ khác nhau.

#### 2.10. Thực thi script `noha_ctl_horizon.sh` để cài đặt Dashboad.
- Cài đặt dashboad để cung cấp giao diện cho OpenStack.
	```sh
	bash noha_ctl_horizon.sh
	```
		
	
### 3. Thực hiện cài đặt trên Compute1 và Compute2 (cài Nova và Neutron)

#### 3.1. Cài đặt Nova và neutron trên Compute1 và Compute2

- Login vào máy Compute1, kiểm tra xem đã có file `config.cfg` trong thư mục root hay chưa. File này được copy khi thực hiện script đầu tiên ở trên node Controller. Nếu chưa có thì copy từ Controller sang. Nếu có rồi thì thực hiện bước dưới.
- Tải script cài đặt nova và neutron cho Compute1

	```sh
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Newton-No-HA/noha_com_install.sh
	
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
	openstack subnet create provider --network provider \
		--allocation-pool start=192.168.40.200,end=192.168.40.220 \
		--dns-nameserver 8.8.8.8 --gateway 192.168.40.254 \
		--subnet-range 192.168.40.0/24 
	```

#### 4.2. Tạo flavor

- Tạo flavor

	```sh
	openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
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
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Newton-No-HA/setup_ip.sh

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
	curl -O https://github.com/congto/openstack-tools/blob/master/scripts/OpenStack-Newton-No-HA/noha_cinder_install.sh

	bash noha_cinder_install.sh
	```

- Sau khi cài đặt xong trên máy chủ cinder, quay lại máy chủ controller kiểm tra xem cinder đã hoạt động hay chưa bằng lệnh.
	```sh
	openstack volume serivce list
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
		

### Cài đặt thêm các thành phần mở rộng khác
### 6. Cài đặt Object storage
- Cần chuẩn bị các máy chủ SWIFT1 và SWIFT2 theo mô hình và ip planning.

#### 6.1. Cấu hình hostname và IP cho các máy chủ `SWIFT1` và `SWIFT2`
#### Thực hiện trên máy chủ SWIFT1
- Login vào máy chủ SWIFT1 với quyền root và thực hiện script dưới.
	```sh 
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Newton-No-HA/setup_ip.sh

	bash setup_ip.sh swift1  192.168.20.37 10.10.0.37 172.16.20.37 192.168.40.37
	```

#### Thực hiện trên máy chủ SWIFT2
- Login vào máy chủ SWIFT1 với quyền root và thực hiện script dưới.
	```sh 
	curl -O https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/OpenStack-Newton-No-HA/setup_ip.sh

	bash setup_ip.sh swift2  192.168.20.38 10.10.0.38 172.16.20.38 192.168.40.38
	```

#### 6.2. Cài đặt Object Storage trên máy chủ controller1 và máy chủ SWIFT1, SWIFT2
##### 6.2.1. Thiết lập các gói bổ trợ cho máy chủ SWIFT1, SWIFT2
- Đứng trên node controller và thực hiện script dưới. Lưu ý, lúc này đang đứng trong thư mục chứa script dưới.
- Thực thi cài đặt script cài đặt các gói bổ trợ cho máy chủ  SWIFT1, SWIFT2. Lưu ý: cần nhập đúng IP của máy chủ  SWIFT1,  SWIFT2. 
	```sh 
	bash noha_node_prepare.sh 192.168.20.37

	bash noha_node_prepare.sh 192.168.20.38
	```

- Trong qúa trình chạy, màn hình sẽ yêu cầu nhập mật khẩu root của máy SWIFT1, SWIFT2. Sau khi thực thi xong, script sẽ cài các gói bổ trợ cho máy chủ SWIFT1, SWIFT2.

- Copy script dùng để cài đặt swift trên máy chủ SWIFT1 và SWIFT2  từ máy chủ Controller sang máy chủ Swift
	```sh
	scp noha_swift_install.sh root@192.168.20.37:/root/

	scp noha_swift_install.sh root@192.168.20.38:/root/
	```

##### 6.2.2. Cài đặt các thành phần của Swift trên các máy chủ swift
- Đứng trên máy chủ swift, thực hiện script dưới để cài đặt các gói và cấu hình Swift.
- Lưu ý: Thực hiện bước này ở cả máy chủ `SWIFT1` và `SWIFT2`
	```sh
	su - 
	
	bash /root/noha_swift_install.sh
	```
- Sau khi cài thực thi xong script trên tại các máy chủ `SWIFT1` và `SWIFT2`, chuyển qua máy chủ controller để thực thi script tiếp.

##### 6.2.3. Cài đặt các thành phần của Swift trên máy chủ controller
- Login vào máy chủ controller với quyền `root` và di duyển vào thư mục chưa script
	```sh
	cd /root/OpenStack-Newton-No-HA
	bash noha_ctl_swift.sh
	```

- Sau khi cài đặt xong, chuyển xuống bước kiểm tra hoạt động của swift

##### 6.2.4. Kiểm tra hoạt động của swift
- Đứng trên node controller thực hiện lệnh dưới để kiểm tra hoạt động của swift
- Chuyển sang tài khoản demo của openstack để kiểm tra hoạt động của swift
	```sh
	source demo-openrc
	```

- Sử dụng lệnh `swift stat` để kiểm tra hoạt động của swift
	```sh
	swift stat
	```
	
	- Kết quả của lệnh như sau
	
		```sh
						Account: AUTH_e55055376e334a5abd37e0d4ba53e172
				 Containers: 0
						Objects: 0
							Bytes: 0
		X-Put-Timestamp: 1501206933.80630
				X-Timestamp: 1501206933.80630
				 X-Trans-Id: tx44caecab4db246bda200e-00597a9995
			 Content-Type: text/plain; charset=utf-8
		```

- Tạo `container` cho swift
	```sh
	openstack container create container1
	```

- Tạo 1 file để up lên swift 
	```sh
	echo "OpenStack" > /root/file_test.txt
	```

- Upload file `file_test.txt` lên container vừa tạo.
	```sh
	cd /root/
	
	openstack object create container1 file_test.txt
	```

- Kiểm tra container1 vừa tạo xem đã có file được up lên hay chưa.
	```sh 
	openstack object list container1
	```

- Down file vừa up bằng lệnh dưới.
	```sh
	openstack object save container1 file_test.txt
	```

- Bạn cũng có thể login vào tài khoản demo để quan sát Object Storage ở tab http://prntscr.com/g18ik9


### 7. Cài đặt Heat
- Thực hiện script `noha_ctl_heat.sh` để cài đặt heat
	```sh
	bash noha_ctl_heat.sh
	````

- Sau khi thực hiện xong script, thực hiện lệnh `openstack orchestration service list` để kiểm tra heat đã hoạt động hay chưa. Kết quả như sau: 
	```sh
	+-------------+-------------+--------------------------------------+-------------+--------+----------------------------+--------+
	| hostname    | binary      | engine_id                            | host        | topic  | updated_at                 | status |
	+-------------+-------------+--------------------------------------+-------------+--------+----------------------------+--------+
	| controller1 | heat-engine | ddcab7f5-04f8-4c78-83e9-976f763db61b | controller1 | engine | 2017-08-15T05:02:18.000000 | up     |
	| controller1 | heat-engine | fc010868-416d-4728-9b0c-fb532d12e5dd | controller1 | engine | 2017-08-15T05:02:18.000000 | up     |
	| controller1 | heat-engine | 4383b86b-0316-4e62-902a-721979e1bc50 | controller1 | engine | 2017-08-15T05:02:18.000000 | up     |
	| controller1 | heat-engine | 6a8e6e4c-4c49-49fc-a698-e906137607fd | controller1 | engine | 2017-08-15T05:02:18.000000 | up     |
	+-------------+-------------+--------------------------------------+-------------+--------+----------------------------+--------+
	```
	
- Tải template mẫu dành cho heat

	```sh
	wget https://raw.githubusercontent.com/congto/openstack-tools/master/scripts/conf/ctl/heat/demo-template.yml
	```

- Chuyển sang project demo để tạo stack ở project demo 

	```sh
	source /root/demo-openrc
	```

- Tạo biến `NET_ID` để sử dụng cho heat ở dưới. Lấy ID của provider network. 

	```sh
	export NET_ID=$(openstack network list | awk '/ provider / { print $2 }')
	```

- Thực hiện tạo stack 

	```sh
	openstack stack create -t demo-template.yml --parameter "NetID=$NET_ID" stack
	```























