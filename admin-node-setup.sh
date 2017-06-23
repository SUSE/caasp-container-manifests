#!/bin/sh
# Update manifest files
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


