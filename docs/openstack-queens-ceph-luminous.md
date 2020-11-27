# Hướng dẫn tích hợp OpenStack Queens với CEPH Luminous

## A. MÔI TRƯỜNG LAB
- Giả lập trên VMware Workstatios, hoặc ESX hoặc Virtualbox hoặc KVM hoặc máy vật lý.
- Centos 7.3 Server 64 bit - 1611

## B. MÔ HÌNH

![noha_openstack_topology.png](/images/noha_openstack_queen_topology.png)

## C. IP PLANNING

![noha_ip_planning.png](/images/noha_openstack_queen_ip_planning.png)

## D. Yêu cầu

- Cài đặt OpenStack theo tài liệu: https://github.com/congto/openstack-tools/blob/master/docs/openstack-queens-CentOS7-scripts.md. Lưu ý: bỏ qua bước 05 trong tài liệu này.

- Cài đặt CEPH Luminous theo tài liệu: https://github.com/congto/ghichep-CEPH/blob/master/docs/luminous/install.md. Lưu ý: Bỏ qua bước 05 trong tài liệu này.

## E. Tích hợp OpenStack và CEPH.

### 1. Cài đặt các gói bổ trợ cho OpenStack.

- Thực hiện trên các node của OpenStack.

- Lần lượt truy cập vào từng node của OpenStack: Controller1, compute1, compute2 để thực hiện cài đặt các gói bổ trợ để OpenStack làm việc với CEPH.

Khai báo repo

```
cat <<EOF> /etc/yum.repos.d/ceph.repo
[ceph]
name=Ceph packages for $basearch
baseurl=https://download.ceph.com/rpm-luminous/el7/x86_64/
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-luminous/el7/noarch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://download.ceph.com/rpm-luminous/el7/SRPMS
enabled=0
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOF
```

- Cài đặt các gói phần mềm cần thiết để OpenStack làm việc với CEPH.

```
yum update -y
yum install -y python-rbd ceph-common
```

### 2. Khai báo các pool trên CEPH

- Thực hiện các bước này trên node `ceph1`.

- Chuyển sang user `cephuser` đã được tạo từ khi cài đặt CEPH cluster.

```
su - cephuser
```

- Khai báo các pools cần thiết đối với OpenStack trên CEPH. Các pools có tên là: `volumes, vms, images, backups`

```
ceph osd pool create volumes 128 128

ceph osd pool create vms 128 128

ceph osd pool create images 128 128

ceph osd pool create backups 128 128
```

- Khởi tạo để các pool này có thể sử dụng được

```
rbd pool init volumes

rbd pool init vms

rbd pool init images

rbd pool init backups
```

- Kiểm tra lại danh sách các pool vừa tạo

```
sudo ceph osd lspools
```

- Kết quả:

```
[cephuser@ceph1 ~]$ sudo ceph osd lspools
1 volumes,2 vms,3 images,4 backups,
```

- Thực hiện copy file `ceph.conf` trên node `ceph1` sang các node: `controller1, compute1, compute2`

```
ssh root@192.168.80.120 sudo tee /etc/ceph/ceph.conf < /etc/ceph/ceph.conf

ssh root@192.168.80.121 sudo tee /etc/ceph/ceph.conf < /etc/ceph/ceph.conf

ssh root@192.168.80.122 sudo tee /etc/ceph/ceph.conf < /etc/ceph/ceph.conf
```

#### 2.1. Tích hợp glance với ceph

#### 2.1.1. Khai báo file cấu hình cho glance trên CEPH.
Login vào node `ceph1` và khai báo file cấu hình dành cho glance

- Chuyển sang user `cephuser`

```
su - cephuser
```

- Tạo file key cho glance

```
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images' > ceph.client.glance.keyring
```

- Copy file `ceph.client.glance.keyring` từ ceph1 sang controller (node cài glance)

```
ceph auth get-or-create client.glance | ssh root@192.168.80.120 sudo tee /etc/ceph/ceph.client.glance.keyring
```

#### 2.1.2. Cấu hình glance để làm việc với CEPH.

Đăng nhập vào node `controller1` (192.168.80.120) để cấu hình glance làm việc với CEPH. Khi cấu hình xong, image của OpenStack sẽ được lưu trên CEPH.

- Kiểm tra xem file `ceph.client.glance.keyring` đã được copy sang hay chưa.

```
ls -alh /etc/ceph
```

- Ta sẽ có kết quả

```
total 20K
drwxr-xr-x   2 root root   54 Feb  2 23:05 .
drwxr-xr-x. 99 root root 8.0K Feb  2 22:57 ..
-rw-r--r--   1 root root   64 Feb  2 23:05 ceph.client.glance.keyring
-rw-r--r--   1 root root   92 Jan 31 04:37 rbdmap
```

- Phân quyền cho cho file `ceph.client.glance.keyring` thuộc sở hữu của user `glance` 

```
sudo chown glance:glance /etc/ceph/ceph.client.glance.keyring
```

- Sau khi phân quyền xong, có thể kiểm tra lại bằng lệnh `ls -alh /etc/ceph`

- Sửa file `/etc/glance/glance-api.conf` để làm việc với CEPH.

```
crudini --set /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
crudini --set /etc/glance/glance-api.conf glance_store default_store rbd
crudini --set /etc/glance/glance-api.conf glance_store stores file,http,rbd
crudini --set /etc/glance/glance-api.conf glance_store rbd_store_pool images
crudini --set /etc/glance/glance-api.conf glance_store rbd_store_user glance
crudini --set /etc/glance/glance-api.conf glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
crudini --set /etc/glance/glance-api.conf glance_store rbd_store_chunk_size 8
```

- Khởi động lại dịch vụ glance 

```
systemctl restart openstack-glance-*
```

- Tạo thử image và kiểm tra xem được lưu trên CEPH hay chưa

```
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

openstack image create "cirros-ceph" \
--file cirros-0.3.4-x86_64-disk.img \
--disk-format qcow2 --container-format bare \
--public
```

- Kiểm tra xem image được up lên hay chưa

```
openstack image list
```

- Đăng nhập vào node `ceph1` và kiểm tra xem pool images đã có image nào hay chưa

```
rbd -p images ls
```

#### 2.2. Tích hợp cinder với ceph
#### 2.2.1. Khai báo file cấu hình cho cinder trên CEPH.

Login vào node `ceph1` và khai báo file cấu hình dành cho cinder. Lưu ý, ta sẽ cấu hình `cinder-volume` và `cinder-backup` sử dụng CEPH.

- Chuyển sang user `cephuser`

```
su - cephuser
```

- Tạo file key cho cinder

```
ceph auth get-or-create client.cinder mon 'allow r, allow command "osd blacklist", allow command "blacklistop"' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=images' > ceph.client.cinder.keyring
```

- Tạo key cho cinder-backup

```
ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' > ceph.client.cinder-backup.keyring
```

- Chuyển file key của cinder (cinder-volume) và cinder-backup sang node `controller1` (192.168.80.120)

```
ceph auth get-or-create client.cinder | ssh root@192.168.80.120 sudo tee /etc/ceph/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder-backup | ssh root@192.168.80.120 sudo tee /etc/ceph/ceph.client.cinder-backup.keyring
```

- Chuyển file key của cinder (cinder-volume) sang node `compute1, compute2`. Lưu ý: Cần chuyển key của cinder từ ceph sang compute bởi vì libvirt trên compute sẽ sử dụng volume do CEPH cấp.

```
ceph auth get-or-create client.cinder | ssh root@192.168.80.121 sudo tee /etc/ceph/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder | ssh root@192.168.80.122 sudo tee /etc/ceph/ceph.client.cinder.keyring

ceph auth get-key client.cinder | ssh root@192.168.80.121 tee /root/client.cinder
ceph auth get-key client.cinder | ssh root@192.168.80.122 tee /root/client.cinder
```

#### 2.2.2. Cấu hình compute để sử dụng volume nằm trên CEPH.

Cấu hình đề libvirtd sử dụng volume sẽ được tích hợp với ceph. Login vào các node compute (192.168.80.121, 192.168.80.122) và thực hiện các bước sau.

- Sinh ra một chuỗi ngẫu nhiên bằng `uuidgen`. Bước này chỉ cần làm trên compute1 để lấy chuỗi bởi vì các compute sẽ sử dụng chung các chuỗi này.

```
uuidgen
````

- Ta sẽ có một chuỗi sinh ra, lưu lại chuỗi này để dùng cho bước tiếp theo:

```
03da04c2-447f-453b-8718-f6696dcc1f12
```

- Tạo file xml để áp cấu hình cho libvirt. Thay chuỗi sinh ra ở trên cho phù hợp. Thực hiện bước này trên cả 02 compute.

```
cat > ceph-secret.xml <<EOF
<secret ephemeral='no' private='no'>
<uuid>03da04c2-447f-453b-8718-f6696dcc1f12</uuid>
<usage type='ceph'>
	<name>client.cinder secret</name>
</usage>
</secret>
EOF
```

- Thực thi lệnh

```
sudo virsh secret-define --file ceph-secret.xml
```

- Ta sẽ có kết quả

```
Secret 03da04c2-447f-453b-8718-f6696dcc1f12 created
```

- Gán giá trị của uuid ở trên. Lưu ý thay chuỗi cho phù hợp. Thực hiện trên cả 02 compute.

```
virsh secret-set-value --secret 03da04c2-447f-453b-8718-f6696dcc1f12 --base64 $(cat /root/client.cinder)
```

- Khởi động lại dịch vụ của nova-compute trên cả 02 compute

```
systemctl restart openstack-nova-compute
```

#### 2.2.3. Cấu hình controller để sử dụng volume nằm trên CEPH.

Login vào node `controller1` và thực hiện các bước tiếp theo.

- Phân quyền cho file key của cinder trên node `Controller1`. Login vào node `controller1` và thực hiện lệnh dưới.

```
sudo chown cinder:cinder /etc/ceph/ceph.client.cinder*
```

- Khai báo lại cấu hình của cinder để làm việc với ceph.

```
crudini --set  /etc/cinder/cinder.conf DEFAULT notification_driver messagingv2
crudini --set  /etc/cinder/cinder.conf DEFAULT enabled_backends ceph
crudini --set  /etc/cinder/cinder.conf DEFAULT glance_api_version 2
crudini --set  /etc/cinder/cinder.conf DEFAULT backup_driver cinder.backup.drivers.ceph
crudini --set  /etc/cinder/cinder.conf DEFAULT backup_ceph_conf /etc/ceph/ceph.conf
crudini --set  /etc/cinder/cinder.conf DEFAULT backup_ceph_user cinder-backup
crudini --set  /etc/cinder/cinder.conf DEFAULT backup_ceph_chunk_size 134217728
crudini --set  /etc/cinder/cinder.conf DEFAULTbackup_ceph_pool backups
crudini --set  /etc/cinder/cinder.conf DEFAULT backup_ceph_stripe_unit 0
crudini --set  /etc/cinder/cinder.conf DEFAULT backup_ceph_stripe_count 0
crudini --set  /etc/cinder/cinder.conf DEFAULT restore_discard_excess_bytes true
crudini --set  /etc/cinder/cinder.conf DEFAULT host ceph

crudini --set  /etc/cinder/cinder.conf ceph volume_driver cinder.volume.drivers.rbd.RBDDriver
crudini --set  /etc/cinder/cinder.conf ceph volume_backend_name ceph
crudini --set  /etc/cinder/cinder.conf ceph rbd_pool volumes
crudini --set  /etc/cinder/cinder.conf ceph rbd_ceph_conf /etc/ceph/ceph.conf
crudini --set  /etc/cinder/cinder.conf ceph rbd_flatten_volume_from_snapshot false
crudini --set  /etc/cinder/cinder.conf ceph rbd_max_clone_depth 5
crudini --set  /etc/cinder/cinder.conf ceph rbd_store_chunk_size 4
crudini --set  /etc/cinder/cinder.conf ceph rados_connect_timeout -1
crudini --set  /etc/cinder/cinder.conf ceph rbd_user cinder

# Thay chuỗi ở dòng tiếp theo cho phù hợp.
crudini --set  /etc/cinder/cinder.conf ceph rbd_secret_uuid 03da04c2-447f-453b-8718-f6696dcc1f12
crudini --set  /etc/cinder/cinder.conf ceph report_discard_supported true
```

- Khởi động lại các dịch vụ của cinder

```
systemctl enable openstack-cinder-backup.service

systemctl restart openstack-cinder-backup.service
```

```
systemctl restart openstack-cinder-api.service openstack-cinder-volume.service openstack-cinder-scheduler.service openstack-cinder-backup.service
```


- Tạo volume type cho cinder

```
cinder type-create ceph

cinder type-key ceph set volume_backend_name=ceph
```

#### 2.2.4. Tạo volume, vm để kiểm chứng việc cinder tích hợp với ceph.

- Kiểm tra image trên hệ thống

```
openstack image list
```

- Kết quả: (lưu ý, image có tên là cirros-ceph đã được up từ bước tích hợp glance với ceph. Ta sẽ sử dụng id của image này `7b9427d2-c13c-4303-b964-7db3d8c194ed`

```
+--------------------------------------+-------------+--------+
| ID                                   | Name        | Status |
+--------------------------------------+-------------+--------+
| c1c193ae-94b6-4e5c-83a9-600eacb3d4f4 | cirros      | active |
| 7b9427d2-c13c-4303-b964-7db3d8c194ed | cirros-ceph | active |
+--------------------------------------+-------------+--------+
```

- Tạo volume với image `cirros-ceph`. Volume này có tên là `ceph-bootable1`, dung lượng là `2G`

```
openstack volume create bootable1 --image 7b9427d2-c13c-4303-b964-7db3d8c194ed --type ceph --size 2
```

- Kiểm tra lại volume vừa tạo bằng lệnh `openstack volume list`, ta có ID của volume `ceph-bootable1` vừa tạo ở trên. Ta sẽ sử dụng ID này cho bước tiếp theo.

```
+--------------------------------------+--------------------+-----------+------+----------------------------------------------+
| ID                                   | Name               | Status    | Size | Attached to                                  |
+--------------------------------------+--------------------+-----------+------+----------------------------------------------+
| 6a380a66-9055-47e6-a0ba-9eacf45d6b76 | ceph-bootable1     | available |    2 |                                              |
| 23fb272e-33c8-4606-84be-0363632a35b2 | volceph02          | in-use    |    2 | Attached to vmvol-ceph01 on /dev/vda         |
| 5a6c4b9d-a58e-491d-b043-b635d0cccd16 | volceph01          | available |    1 |                                              |
+--------------------------------------+--------------------+-----------+------+----------------------------------------------+
```

- Lấy ID của network mà máy ảo sẽ gắn vào bằng lệnh `openstack network list`. Lưu chuỗi ID để sử dụng ở bước dưới.

```
+--------------------------------------+----------+--------------------------------------+
| ID                                   | Name     | Subnets                              |
+--------------------------------------+----------+--------------------------------------+
| c0f72c47-b6f2-4187-844b-a35b8afb8764 | provider | a65f8ca9-9e14-4830-bcc1-2b9079426f93 |
+--------------------------------------+----------+--------------------------------------+
```

- Tạo một VM được boot từ volume `ceph-bootable1` ở trên.

```
nova boot --flavor m1.tiny \
 --boot-volume 6a380a66-9055-47e6-a0ba-9eacf45d6b76 \
 --nic net-id=c0f72c47-b6f2-4187-844b-a35b8afb8764 \
 --security-group default \
 cirros-cephvolumes-instance1 
```

- Ta sẽ có output 

```
+--------------------------------------+-------------------------------------------------+
| Property                             | Value                                           |
+--------------------------------------+-------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                          |
| OS-EXT-AZ:availability_zone          |                                                 |
| OS-EXT-SRV-ATTR:host                 | -                                               |
| OS-EXT-SRV-ATTR:hostname             | cirros-cephvolumes-instance1                    |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | -                                               |
| OS-EXT-SRV-ATTR:instance_name        |                                                 |
| OS-EXT-SRV-ATTR:kernel_id            |                                                 |
| OS-EXT-SRV-ATTR:launch_index         | 0                                               |
| OS-EXT-SRV-ATTR:ramdisk_id           |                                                 |
| OS-EXT-SRV-ATTR:reservation_id       | r-y0jo11ku                                      |
| OS-EXT-SRV-ATTR:root_device_name     | -                                               |
| OS-EXT-SRV-ATTR:user_data            | -                                               |
| OS-EXT-STS:power_state               | 0                                               |
| OS-EXT-STS:task_state                | scheduling                                      |
| OS-EXT-STS:vm_state                  | building                                        |
| OS-SRV-USG:launched_at               | -                                               |
| OS-SRV-USG:terminated_at             | -                                               |
| accessIPv4                           |                                                 |
| accessIPv6                           |                                                 |
| adminPass                            | 4E6qMP3ZbNjk                                    |
| config_drive                         |                                                 |
| created                              | 2020-02-03T09:35:48Z                            |
| description                          | -                                               |
| flavor:disk                          | 10                                              |
| flavor:ephemeral                     | 0                                               |
| flavor:extra_specs                   | {}                                              |
| flavor:original_name                 | m1.tiny                                         |
| flavor:ram                           | 512                                             |
| flavor:swap                          | 0                                               |
| flavor:vcpus                         | 1                                               |
| hostId                               |                                                 |
| host_status                          |                                                 |
| id                                   | e437b301-f6e0-477b-b119-28812ab7b78c            |
| image                                | Attempt to boot from volume - no image supplied |
| key_name                             | -                                               |
| locked                               | False                                           |
| metadata                             | {}                                              |
| name                                 | cirros-cephvolumes-instance1                    |
| os-extended-volumes:volumes_attached | []                                              |
| progress                             | 0                                               |
| security_groups                      | default                                         |
| status                               | BUILD                                           |
| tags                                 | []                                              |
| tenant_id                            | 6a0576514b68435996d959b1f146afb2                |
| updated                              | 2020-02-03T09:35:48Z                            |
| user_id                              | f29202535ab84bd0a82f18ae9a28a5d7                |
+--------------------------------------+-------------------------------------------------+
```

- Chờ một lát và kiểm tra lại danh sách server xem đã tạo được hay chưa bằng lệnh `openstack server list`. Ta sẽ có kết quả của vm `cirros-cephvolumes-instance1` tương ứng với IP là `192.168.84.208`

```
+--------------------------------------+------------------------------+---------+-------------------------+-------------+---------+
| ID                                   | Name                         | Status  | Networks                | Image       | Flavor  |
+--------------------------------------+------------------------------+---------+-------------------------+-------------+---------+
| e437b301-f6e0-477b-b119-28812ab7b78c | cirros-cephvolumes-instance1 | ACTIVE  | provider=192.168.84.208 |             | m1.tiny |
| b856d3fe-59db-4184-b9c1-06077461f784 | vmvol-ceph01                 | ACTIVE  | provider=192.168.84.203 |             | m1.nano |
| e880e6a7-ab3d-4546-a753-e6783ca38be5 | Provider_VM02                | ACTIVE  | provider=192.168.84.202 | cirros-ceph | m1.nano |
| 6dfba7c6-236e-4471-b39f-8d5b910440c6 | Provider-volume-vm1          | SHUTOFF | provider=192.168.84.204 |             | m1.nano |
| 79ba0b5b-e318-4472-8b1c-f0a1a566a3e5 | Provider_VM01                | ACTIVE  | provider=192.168.84.206 | cirros      | m1.nano |
+--------------------------------------+------------------------------+---------+-------------------------+-------------+---------+
```

Ta có thể ping thử hoặc ssh với tài khoản `cirros` và mật khẩu là `cubswin:)` để kiểm chứng.

```
$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast qlen 1000
    link/ether fa:16:3e:8d:82:50 brd ff:ff:ff:ff:ff:ff
    inet 192.168.84.208/24 brd 192.168.84.255 scope global eth0
    inet6 fe80::f816:3eff:fe8d:8250/64 scope link 
       valid_lft forever preferred_lft forever
$ ping dantri.com
PING dantri.com (222.255.27.51): 56 data bytes
64 bytes from 222.255.27.51: seq=0 ttl=56 time=2.190 ms
^C
--- dantri.com ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 2.190/2.190/2.190 ms
$ uptime
 09:38:39 up 2 min,  1 users,  load average: 0.00, 0.01, 0.00
$ 
```

#### 2.3. Tích hợp nova với ceph

Khi chưa tích hợp nova với ceph thì lúc tạo VM mà boot từ image thì file disk của VM đó được lưu ngay trên node compute. Sau khi tích hợp nova với ceph thì file disk của máy ảo lúc này sẽ lưu trên ceph.

#### 2.3.1. Khai báo file key cho nova

Login vào node `ceph1` và khai báo file cấu hình dành cho cinder. Lưu ý, ta sẽ cấu hình `cinder-volume` và `cinder-backup` sử dụng CEPH.

- Chuyển sang user `cephuser`

```
su - cephuser
```

- Thực hiện tạo file key

```
ceph auth get-or-create client.nova mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=vms, allow rx pool=images' > ceph.client.nova.keyring 
```

- Copy file key sang các node `compute1` và `compute2`

```
ceph auth get-or-create client.nova | ssh root@192.168.80.121 sudo tee /etc/ceph/ceph.client.nova.keyring 
ceph auth get-or-create client.nova | ssh root@192.168.80.122 sudo tee /etc/ceph/ceph.client.nova.keyring 

ceph auth get-key client.nova | ssh root@192.168.80.121 tee /root/client.nova
ceph auth get-key client.nova | ssh root@192.168.80.12 tee /root/client.nova
```

#### 2.3.2. Cấu hình nova sử dụng ceph

Đăng nhập vào các node compute để thực hiện các bước sau.

- Đăng nhập vào node `compute1` để tạo uuid. Chỉ cần thực hiện trên một compute, chuỗi sinh ra được sử dụng cho tất cả các node compute. Hãy lưu kết quả của chuỗi lại.

```
uuidgen
```

- Ta có kết quả như bên dưới, hãy sử dụng chuỗi theo kết quả mà bạn nhận được.

```
379379ff-06ec-4524-9846-45f2366d549d
```

- Đăng nhập vào cả 02 compute và khai báo file xml

```
cat << EOF > nova-ceph.xml
<secret ephemeral="no" private="no">
<uuid>379379ff-06ec-4524-9846-45f2366d549d</uuid>
<usage type="ceph">
<name>client.nova secret</name>
</usage>
</secret>
EOF
```

- Thực hiện khai báo cho file xml trên cả 02 compute

```
sudo virsh secret-define --file nova-ceph.xml
```

- Gán giá trị của file client.nova

```
virsh secret-set-value --secret 379379ff-06ec-4524-9846-45f2366d549d --base64 $(cat /root/client.nova)
```

- Sửa file cấu hình của nova

```
crudini --set  /etc/nova/nova.conf libvirt images_rbd_pool vms
crudini --set  /etc/nova/nova.conf libvirt images_type rbd

## Luu y thay chuoi cho phu hop
crudini --set  /etc/nova/nova.conf libvirt rbd_secret_uuid 379379ff-06ec-4524-9846-45f2366d549d

crudini --set  /etc/nova/nova.conf libvirt rbd_user nova
crudini --set  /etc/nova/nova.conf libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf
```

- Khởi động lại nova-compute trên cả 02 node compute.

```
systemctl restart openstack-nova-compute 
```

#### 2.3.3. Tạo VM để kiểm chứng việc tích hợp nova và ceph.

Đăng nhập vào node controller để tạo VM.

- Convert image từ file img sang file raw để đưa vào ceph. Giả sử file image đã được tải vể.

```
qemu-img convert -f qcow2 -O raw /root/cirros-0.3.4-x86_64-disk.img /root/cirros-0.3.4-x86_64-disk.raw
```

- Tạo file image đưa vào ceph với định dạng raw (lưu ý trước đó glance cần được tích hợp với ceph)

```
openstack image create "cirros-raw" \
--file cirros-0.3.4-x86_64-disk.raw \
--disk-format raw --container-format bare \
--public 
```

- Kiểm tra lại danh sách image, trong đó sẽ thấy có image với tên là `cirros-raw` bằng lệnh `openstack image list`. Lưu ý dòng ID để sử dụng ở bước dưới.

```
[root@controller1 ~]# openstack image list
+--------------------------------------+-------------+--------+
| ID                                   | Name        | Status |
+--------------------------------------+-------------+--------+
| c1c193ae-94b6-4e5c-83a9-600eacb3d4f4 | cirros      | active |
| 7b9427d2-c13c-4303-b964-7db3d8c194ed | cirros-ceph | active |
| f7763f1f-0c51-4b69-b074-acd720847687 | cirros-img  | active |
| 1712cfd8-bada-4cef-8833-71005d59761f | cirros-raw  | active |
+--------------------------------------+-------------+--------+
```

- Kiểm tra lại danh sách network bằng lệnh `openstack network list`. Ta sẽ thu được danh sách network, lựa chọn dòng ID của network mà VM sẽ gắn vào. Kết quả của lệnh như sau:

```
[root@controller1 ~]# openstack network list
+--------------------------------------+----------+--------------------------------------+
| ID                                   | Name     | Subnets                              |
+--------------------------------------+----------+--------------------------------------+
| c0f72c47-b6f2-4187-844b-a35b8afb8764 | provider | a65f8ca9-9e14-4830-bcc1-2b9079426f93 |
+--------------------------------------+----------+--------------------------------------+
```

- Tạo máy ảo boot từ image 

```
nova boot --flavor m1.tiny --image cirros-raw --nic net-id=c0f72c47-b6f2-4187-844b-a35b8afb8764 --security-group default cirros-cephrbd-instance1
```

- Kết quả sẽ thông báo như bên dưới

```
+--------------------------------------+---------------------------------------------------+
| Property                             | Value                                             |
+--------------------------------------+---------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                            |
| OS-EXT-AZ:availability_zone          |                                                   |
| OS-EXT-SRV-ATTR:host                 | -                                                 |
| OS-EXT-SRV-ATTR:hostname             | cirros-cephrbd-instance1                          |
| OS-EXT-SRV-ATTR:hypervisor_hostname  | -                                                 |
| OS-EXT-SRV-ATTR:instance_name        |                                                   |
| OS-EXT-SRV-ATTR:kernel_id            |                                                   |
| OS-EXT-SRV-ATTR:launch_index         | 0                                                 |
| OS-EXT-SRV-ATTR:ramdisk_id           |                                                   |
| OS-EXT-SRV-ATTR:reservation_id       | r-nnv056fm                                        |
| OS-EXT-SRV-ATTR:root_device_name     | -                                                 |
| OS-EXT-SRV-ATTR:user_data            | -                                                 |
| OS-EXT-STS:power_state               | 0                                                 |
| OS-EXT-STS:task_state                | scheduling                                        |
| OS-EXT-STS:vm_state                  | building                                          |
| OS-SRV-USG:launched_at               | -                                                 |
| OS-SRV-USG:terminated_at             | -                                                 |
| accessIPv4                           |                                                   |
| accessIPv6                           |                                                   |
| adminPass                            | N6dxLXF7SVyL                                      |
| config_drive                         |                                                   |
| created                              | 2020-02-03T14:15:04Z                              |
| description                          | -                                                 |
| flavor:disk                          | 10                                                |
| flavor:ephemeral                     | 0                                                 |
| flavor:extra_specs                   | {}                                                |
| flavor:original_name                 | m1.tiny                                           |
| flavor:ram                           | 512                                               |
| flavor:swap                          | 0                                                 |
| flavor:vcpus                         | 1                                                 |
| hostId                               |                                                   |
| host_status                          |                                                   |
| id                                   | 41351352-aa18-4d4a-8b78-ad50fcec039c              |
| image                                | cirros-raw (1712cfd8-bada-4cef-8833-71005d59761f) |
| key_name                             | -                                                 |
| locked                               | False                                             |
| metadata                             | {}                                                |
| name                                 | cirros-cephrbd-instance1                          |
| os-extended-volumes:volumes_attached | []                                                |
| progress                             | 0                                                 |
| security_groups                      | default                                           |
| status                               | BUILD                                             |
| tags                                 | []                                                |
| tenant_id                            | 6a0576514b68435996d959b1f146afb2                  |
| updated                              | 2020-02-03T14:15:04Z                              |
| user_id                              | f29202535ab84bd0a82f18ae9a28a5d7                  |
+--------------------------------------+---------------------------------------------------+
```

- Kiểm chứng lại lại danh sách server bằng lệnh `openstack server list`, trong đó lưu ý dòng có tên server là `cirros-cephrbd-instance1`.

```
[root@controller1 ~]# openstack server list
+--------------------------------------+------------------------------+---------+-------------------------+-------------+---------+
| ID                                   | Name                         | Status  | Networks                | Image       | Flavor  |
+--------------------------------------+------------------------------+---------+-------------------------+-------------+---------+
| 41351352-aa18-4d4a-8b78-ad50fcec039c | cirros-cephrbd-instance1     | ACTIVE  | provider=192.168.84.207 | cirros-raw  | m1.tiny |
| e437b301-f6e0-477b-b119-28812ab7b78c | cirros-cephvolumes-instance1 | ACTIVE  | provider=192.168.84.208 |             | m1.tiny |
| b856d3fe-59db-4184-b9c1-06077461f784 | vmvol-ceph01                 | ACTIVE  | provider=192.168.84.203 |             | m1.nano |
| e880e6a7-ab3d-4546-a753-e6783ca38be5 | Provider_VM02                | ACTIVE  | provider=192.168.84.202 | cirros-ceph | m1.nano |
| 6dfba7c6-236e-4471-b39f-8d5b910440c6 | Provider-volume-vm1          | SHUTOFF | provider=192.168.84.204 |             | m1.nano |
| 79ba0b5b-e318-4472-8b1c-f0a1a566a3e5 | Provider_VM01                | ACTIVE  | provider=192.168.84.206 | cirros      | m1.nano |
+--------------------------------------+------------------------------+---------+-------------------------+-------------+---------+
```

Ta có thể ping hoặc ssh tới VM có IP là: `192.168.84.207`

- Chuyển sang node `ceph1` và kiểm tra xem pools `vms` đã có rbd image nào hay chưa bằng lệnh `rbd -p vms ls`. Ta có kết quả như bên dưới.

```
[cephuser@ceph1 ~]$ rbd -p vms ls
41351352-aa18-4d4a-8b78-ad50fcec039c_disk
```

- Kiểm tra thông tin của rbd image có tên là `41351352-aa18-4d4a-8b78-ad50fcec039c_disk` bằng lệnh dưới.

```
rbd -p vms info 41351352-aa18-4d4a-8b78-ad50fcec039c_disk
```

- Kết quả trả về sẽ là

```
[cephuser@ceph1 ~]$ rbd -p vms info 41351352-aa18-4d4a-8b78-ad50fcec039c_disk
rbd image '41351352-aa18-4d4a-8b78-ad50fcec039c_disk':
        size 10GiB in 1280 objects
        order 23 (8MiB objects)
        block_name_prefix: rbd_data.6a94794324a5
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
        flags:
        create_timestamp: Mon Feb  3 21:15:14 2020
        parent: images/1712cfd8-bada-4cef-8833-71005d59761f@snap
        overlap: 39.2MiB
```

Tới đây đã kết thúc việc tích hợp CEPH với: Glance để lưu image, Cinder để lưu volume, Nova để lưu disk của VM khi boot từ image.

