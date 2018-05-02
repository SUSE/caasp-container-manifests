#!/bin/sh
# activate the dashboard
# this script WILL BE RUN ONLY ONCE, after the installation
# this script WILL NOT RUN during/after upgrades

# Make sure that the controller node looks for the local pause image
# TODO: remove this as soon as possible. As an idea, we could use a systemd drop-in unit.

if hostnamectl | grep -q [Kk]ubic; then
  DIST=kubic
else
  DIST=sles12
fi

if ! grep "pod-infra-container-image" /etc/kubernetes/kubelet &> /dev/null; then
  sed -i "s|^KUBELET_ARGS=\"|KUBELET_ARGS=\"--pod-infra-container-image=$DIST/pause:1.0.0 |" /etc/kubernetes/kubelet
fi

# Make sure etcd listens on 0.0.0.0
sed -i 's@#\?ETCD_LISTEN_CLIENT_URLS.*@ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379@' /etc/sysconfig/etcd

# Generate root ssh key and share it with velum
# https://bugzilla.suse.com/show_bug.cgi?id=1030876
if ! [ -f /root/.ssh/id_rsa ]; then
  ssh-keygen -b 4096 -f /root/.ssh/id_rsa -t rsa -N ""
fi
[ -d /var/lib/misc/ssh-public-key  ] || mkdir -p /var/lib/misc/ssh-public-key
cp /root/.ssh/id_rsa.pub /var/lib/misc/ssh-public-key

# Connect the salt-minion running in the administration controller node to the local salt-master
# instance that is running in a container
cat <<EOF > /etc/salt/grains
roles:
- admin
EOF
echo "master: localhost" > /etc/salt/minion.d/minion.conf
echo "id: admin" > /etc/salt/minion.d/minion_id.conf

# Disable swap
# On ISO-based installs the script runs in a chroot and then the system is rebooted
sed -i '/^#/! {/ swap / s/^/#/}' /etc/fstab
