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
 