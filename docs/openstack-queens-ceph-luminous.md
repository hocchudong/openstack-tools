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













