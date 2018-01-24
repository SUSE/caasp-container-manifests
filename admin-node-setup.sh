#!/bin/sh
# this script WILL BE RUN ON EVERY REBOOT

# Clear the transactional update grains when booting up
if [ -f /etc/salt/grains ]; then
    sed -i -e 's|tx_update_reboot_needed:.*|tx_update_reboot_needed: false|g' /etc/salt/grains
fi

# Turn off current swaps if any
/usr/sbin/swapoff -a

# switch deprecated --config flag in kubelet
sed -i -e "s/--config=/--pod-manifest-path=/g" /etc/kubernetes/kubelet

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

# First time setup of user-configuration for salt-master
if [ ! -d "/etc/caasp" ]; then
    mkdir /etc/caasp
fi

if [ ! -f "/etc/caasp/salt-master-custom.conf" ]; then
    echo "# Custom Configurations for Salt-Master" > /etc/caasp/salt-master-custom.conf
fi

# Generate TLS CA and Initial Certificates
/usr/share/caasp-container-manifests/gen-certs.sh

VELUM_CRT_FINGERPRINT_SHA1=$(openssl x509 -noout -in /etc/pki/velum.crt -fingerprint -sha1 | cut -d= -f2)
VELUM_CRT_FINGERPRINT_SHA256=$(openssl x509 -noout -in /etc/pki/velum.crt -fingerprint -sha256 | cut -d= -f2)

# Generate issue file with Velum details
# https://bugzilla.suse.com/show_bug.cgi?id=1031682
cat <<EOF > /etc/issue.d/90-velum.conf

You can manage your cluster by opening the web application running on
port 443 of this node from your browser: https://<this-node>

You can also check that the instance you are accessing matches the
certificate fingerprints presented to your browser:

Velum SHA1 fingerprint:   $VELUM_CRT_FINGERPRINT_SHA1
Velum SHA256 fingerprint: $VELUM_CRT_FINGERPRINT_SHA256
EOF
