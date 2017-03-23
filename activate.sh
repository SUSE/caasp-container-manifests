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
if [ ! -f $manifest_dir/salt.yaml ]; then
    echo "salt.yaml is not in $manifest_dir" >&2
    exit -3
fi
if [ ! -f $manifest_dir/velum.yaml ]; then
    echo "velum.yaml is not in $manifest_dir" >&2
    exit -3
fi
cp -v $manifest_dir/salt.yaml $kube_dir
cp -v $manifest_dir/velum.yaml $kube_dir

if [ "$YAST_IS_RUNNING" = instsys ]; then
    # YaST is configuring controller node
    # enable specific services to ControllerNode
    systemctl enable docker
    systemctl enable kubelet
else
    # cloud-init is configuring controller node
    # enable and start specific services to ControllerNode
    systemctl enable --now docker
    systemctl enable --now kubelet
fi

