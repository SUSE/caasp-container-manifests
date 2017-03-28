#!/bin/sh

kube_dir=/etc/kubernetes/manifests
manifest_dir=/usr/share/caasp-container-manifests
overwrite=1

while [ $# -gt 0 ] ; do
  case $1 in
    --kube-dir)
      kube_dir="$2"
      shift
      ;;
    --manifests-dir)
      manifest_dir="$2"
      shift
      ;;
    --do-not-overwrite)
      overwrite=
      ;;
    *)
      abort "Unknown argument $1"
      ;;
  esac
  shift
done

#########################################################

mkdir -p $kube_dir
for i in $manifest_dir/*.yaml ; do
    echo "Copying $(basename $i) to $kube_dir"
    if [ -f "$kube_dir/$(basename $i)" ] ; then
        [ -n "$overwrite" ] && cp "$i" "$kube_dir/" || echo "... skipped"
    else
        cp "$i" "$kube_dir/"
    fi
done

# Make sure that the controller node looks for the local pause image
# TODO: remove this as soon as possible. As an idea, we could use a systemd drop-in unit.
sed -i 's|--config=/etc/kubernetes/manifests|--config=/etc/kubernetes/manifests --pod-infra-container-image=sles12/pause:1.0.0|g' /etc/kubernetes/kubelet

# Make sure etcd listens on 0.0.0.0
sed -i 's@#\?ETCD_LISTEN_PEER_URLS.*@ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380@' /etc/sysconfig/etcd
sed -i 's@#\?ETCD_LISTEN_CLIENT_URLS.*@ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379@' /etc/sysconfig/etcd

# TODO: these services should have been enabled by default
if [ "$YAST_IS_RUNNING" = instsys ]; then
    # YaST is configuring controller node
    # enable specific services to ControllerNode
    systemctl enable docker
    systemctl enable kubelet
    systemctl enable etcd
else
    # cloud-init is configuring controller node
    # enable and start specific services to ControllerNode
    systemctl enable --now docker
    systemctl enable --now kubelet
    systemctl enable --now etcd
fi
