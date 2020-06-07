yum install etcd -y

cp /etc/etcd/etcd.conf /etc/etcd/etcd.conf.orig

sed -i '/ETCD_DATA_DIR=/cETCD_DATA_DIR="/var/lib/etcd/default.etcd"' /etc/etcd/etcd.conf

sed -i '/ETCD_LISTEN_PEER_URLS=/cETCD_LISTEN_PEER_URLS="http://10.24.44.171:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_LISTEN_CLIENT_URLS=/cETCD_LISTEN_CLIENT_URLS="http://10.24.44.171:2379"' /etc/etcd/etcd.conf

sed -i '/ETCD_NAME=/cETCD_NAME="controller1"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_ADVERTISE_PEER_URLS=/cETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.24.44.171:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_ADVERTISE_CLIENT_URLS=/cETCD_ADVERTISE_CLIENT_URLS="http://10.24.44.171:2379"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_CLUSTER=/cETCD_INITIAL_CLUSTER="controller1=http://10.24.44.171:2380"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_CLUSTER_TOKEN=/cETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"' /etc/etcd/etcd.conf

sed -i '/ETCD_INITIAL_CLUSTER_STATE=/cETCD_INITIAL_CLUSTER_STATE="new"' /etc/etcd/etcd.conf

systemctl enable etcd

systemctl restart etcd

systemctl status etcd



