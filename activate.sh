#!/bin/sh
kube_dir=/etc/kubernetes/manifests
manifest_dir=/usr/share/caasp-container-manifests
if [ ! -d $kube_dir ]; then
    echo "$kube_dir does not exist" >&2
    echo "make sure kubernetes is installed" >&2
    exit -1
fi
if [ ! -d $manifest_dir ]; then
    echo "$manifest_dir does not exist" >&2
    echo "manifest files are expected to be there" >&2
    exit -2
fi
if [ ! -f $manifest_dir/public.yaml ]; then
    echo "public.yaml is not in $manifest_dir" >&2
    exit -3
fi
if [ ! -f $manifest_dir/private.yaml ]; then
    echo "private.yaml is not in $manifest_dir" >&2
    exit -3
fi
cp -v $manifest_dir/public.yaml $kube_dir
cp -v $manifest_dir/private.yaml $kube_dir

# Make sure that the controller node looks for the local pause image
# TODO: remove this as soon as possible. As an idea, we could use a systemd drop-in unit.
if ! grep "pod-infra-container-image" /etc/kubernetes/kubelet &> /dev/null; then
  sed -i 's|^KUBELET_ARGS="|KUBELET_ARGS="--pod-infra-container-image=sles12/pause:1.0.0 |' /etc/kubernetes/kubelet
fi

# Make sure etcd listens on 0.0.0.0
sed -i 's@#\?ETCD_LISTEN_PEER_URLS.*@ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380@' /etc/sysconfig/etcd
sed -i 's@#\?ETCD_LISTEN_CLIENT_URLS.*@ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379@' /etc/sysconfig/etcd

# https://bugzilla.suse.com/show_bug.cgi?id=1031682
cat <<EOF > /etc/issue.d/100-velum.conf
You can manage your cluster by opening the web application running on
port 80 of this node from your browser.

EOF

# Generate root ssh key and share it with velum
# https://bugzilla.suse.com/show_bug.cgi?id=1030876
if ! [ -f /root/.ssh/id_rsa ]; then
  ssh-keygen -b 4096 -f /root/.ssh/id_rsa -t rsa -N ""
fi
[ -d /var/lib/misc/ssh-public-key  ] || mkdir -p /var/lib/misc/ssh-public-key
cp /root/.ssh/id_rsa.pub /var/lib/misc/ssh-public-key

# Create MariaDB system user, bsc#1034885
groupadd -g 331 mysql
useradd -r -u 60 -g mysql -c "MySQL database admin" -d /var/lib/mysql -s /bin/false mysql

# Connect the salt-minion running in the administration controller node to the local salt-master
# instance that is running in a container
cat <<EOF > /etc/salt/grains
roles:
- admin
EOF
echo "master: localhost" > /etc/salt/minion.d/minion.conf
echo "id: admin" > /etc/salt/minion.d/minion_id.conf

systemctl enable salt-minion
