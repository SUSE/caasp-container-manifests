#!/bin/sh
# this script WILL BE RUN ON EVERY REBOOT

# Clear the transactional update grains when booting up
if [ -f /etc/salt/grains ]; then
    sed -i -e 's|tx_update_reboot_needed:.*|tx_update_reboot_needed: false|g' /etc/salt/grains
fi

# Update manifest files
kube_dir=/etc/kubernetes/manifests
manifest_dir=/usr/share/caasp-container-manifests
images_dir=/usr/share/suse-docker-images/native

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

tmp_dir=$(mktemp -d)

cp $manifest_dir/public.yaml $tmp_dir
cp $manifest_dir/private.yaml $tmp_dir

for i in $(ls $images_dir/sles*.tag);do
    metadata_file=$(basename $i .tag).metadata
    image_name=$(cat $images_dir/$metadata_file | grep \"name\": | cut -d":" -f2 | cut -d\" -f2)
    tag=$(cat $i)
    echo "$0: Setting $image_name:$tag into public and private manifests"
    sed -i -e "s%$image_name:__TAG__%$image_name:$tag%g" $tmp_dir/public.yaml
    sed -i -e "s%$image_name:__TAG__%$image_name:$tag%g" $tmp_dir/private.yaml
done
echo "$0: Replacing public and private manifests"
cp $tmp_dir/public.yaml $kube_dir
cp $tmp_dir/private.yaml $kube_dir

rm -rf $tmp_dir

# switch deprecated --config flag in kubelet
sed -i -e "s/--config=/--pod-manifest-path=/g" /etc/kubernetes/kubelet
