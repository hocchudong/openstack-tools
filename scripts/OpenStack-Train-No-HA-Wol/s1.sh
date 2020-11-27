hostnamectl set-hostname controller1

echo "127.0.0.1 localhost `hostname`" > /etc/hosts
echo "10.24.44.171 controller1" >> /etc/hosts
echo "10.24.44.172 compute1" >> /etc/hosts
echo "10.24.44.173 compute2" >> /etc/hosts

echo "Setup IP  eth0"
nmcli con modify eth0 ipv4.addresses 10.24.74.171/24
nmcli con modify eth0 ipv4.method manual
nmcli con modify eth0 connection.autoconnect yes

echo "Setup IP  eth1"
nmcli con modify eth1 ipv4.addresses 10.24.44.171/24
nmcli con modify eth1 ipv4.gateway 10.24.44.1
nmcli con modify eth1 ipv4.dns 130.130.130.130
nmcli con modify eth1 ipv4.method manual
nmcli con modify eth1 connection.autoconnect yes

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo systemctl disable firewalld
sudo systemctl stop firewalld
sudo systemctl stop NetworkManager
sudo systemctl disable NetworkManager
sudo systemctl enable network
sudo systemctl start network

init 6
