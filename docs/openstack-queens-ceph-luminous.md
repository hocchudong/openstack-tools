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
- Login vào node `ceph1` và khai báo file cấu hình dành cho glance

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

