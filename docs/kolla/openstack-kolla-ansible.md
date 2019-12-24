## Ghi chép cài đặt OpenStack bằng Kolla-ansible

# Kolla-ansible đối với mô hình all-in-one.


## Chuẩn bị 
- OS CentOS 7
- 02 NICs


## Cài đặt

### Hostname và cấu hình cơ bản


### Cài đặt gói bổ trợ

- Cài đặt các gói bổ trợ
    ```
    yum install -y epel-release 

    yum install git vim byobu -y

    yum install -y python-pip
    pip install -U pip
    yum install -y python-devel libffi-devel gcc openssl-devel libselinux-python
    pip install -U ansible


    ```