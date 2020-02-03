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
ceph auth get-or-create client.cinder | ssh 192.168.80.120 sudo tee /etc/ceph/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder-backup | ssh 192.168.80.120 sudo tee /etc/ceph/ceph.client.cinder-backup.keyring
```

- Chuyển file key của cinder (cinder-volume) sang node `compute1, compute2`. Lưu ý: Cần chuyển key của cinder từ ceph sang compute bởi vì libvirt trên compute sẽ sử dụng volume do CEPH cấp.

```
ceph auth get-or-create client.cinder | ssh 192.168.80.121 sudo tee /etc/ceph/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder | ssh 192.168.80.122 sudo tee /etc/ceph/ceph.client.cinder.keyring

ceph auth get-key client.cinder | ssh 192.168.80.121 tee /root/client.cinder
ceph auth get-key client.cinder | ssh 192.168.80.122 tee /root/client.cinder
```

#### 2.2.2. Cấu hình compute để sử dụng volume nằm trên CEPH.

Cấu hình đề libvirtd sử dụng volume sẽ được tích hợp với ceph. Login vào các node compute (192.168.80.121, 192.168.80.122) và thực hiện các bước sau.

- Sinh ra một chuỗi ngẫu nhiên bằng `uuidgen`

```
uuidgen
````

- Ta sẽ có một chuỗi sinh ra, lưu lại chuỗi này để dùng cho bước tiếp theo:

```

```

- Tạo file xml để áp cấu hình cho libvirt. Thay chuỗi sinh ra ở trên cho phù hợp.

```
cat > ceph-secret.xml <<EOF
<secret ephemeral='no' private='no'>
<uuid>414ba151-4068-40c6-9d7b-84998ce6a5a6</uuid>
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

```

- Gán giá trị của uuid ở trên. Lưu ý thay chuỗi cho phù hợp.

```
virsh secret-set-value --secret 414ba151-4068-40c6-9d7b-84998ce6a5a6 --base64 $(cat /root/client.cinder)
```

- Khởi động lại dịch vụ của nova-compute

```
systemctl restart openstack-nova-compute
```

#### 2.2.2. Cấu hình controller để sử dụng volume nằm trên CEPH.

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


crudini --set  /etc/cinder/cinder.conf  ceph volume_driver cinder.volume.drivers.rbd.RBDDriver
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver volume_backend_name ceph
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver rbd_pool volumes
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver rbd_ceph_conf /etc/ceph/ceph.conf
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver rbd_flatten_volume_from_snapshot false
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver rbd_max_clone_depth 5
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver rbd_store_chunk_size 4
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver rados_connect_timeout -1
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver rbd_user cinder
# Thay chuỗi ở dòng tiếp theo cho phù hợp.
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver rbd_secret_uuid 414ba151-4068-40c6-9d7b-84998ce6a5a6
crudini --set  /etc/cinder/cinder.conf  ceph volume_driver report_discard_supported true
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




















