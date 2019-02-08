#!/bin/sh
# this script WILL BE RUN ON EVERY REBOOT

# Clear the transactional update grains when booting up
if [ -f /etc/salt/grains ]; then
    sed -i -e 's|tx_update_reboot_needed:.*|tx_update_reboot_needed: false|g' /etc/salt/grains
fi

# Turn off current swaps if any
/usr/sbin/swapoff -a

# Update manifest files
kube_dir=/etc/kubernetes/manifests
manifest_dir=/usr/share/caasp-container-manifests/manifests
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

# If the configuration file contains the statement:
#
# --pod-manifest-path=/etc/kubernetes/kubelet-config.yaml
#
# It was updated by the admin-setup.sh script incorrectly. In that case we
# have to replace the `--pod-manifest-path` with `--config` again
# Details: https://bugzilla.suse.com/show_bug.cgi?id=1124187
# TODO: Remove with v4 release when no longer needed.
if grep -q -- '--pod-manifest-path=/etc/kubernetes/kubelet-config.yaml' /etc/kubernetes/kubelet ; then
    echo "Fixing pod-manifests-path to config in kubelet file"
    sed -i 's/--pod-manifest-path/--config/g' /etc/kubernetes/kubelet
fi

tmp_dir=$(mktemp -d)

cp $manifest_dir/*.yaml $tmp_dir

for i in $(ls $images_dir/sles*.tag $images_dir/kubic*.tag);do
    metadata_file=$(basename $i .tag).metadata
    image_name=$(cat $images_dir/$metadata_file | grep \"name\": | cut -d":" -f2 | cut -d\" -f2)
    tag=$(cat $i)

    echo "$0: Setting $image_name:$tag into manifests"
    sed -i -e "s%$image_name:__TAG__%$image_name:$tag%g" $tmp_dir/*.yaml
done

# TODO: We also need to delete old manifest files, if/when
#       we delete manifests. Something like this:
# rsync -r --delete $tmp_dir/ $kube_dir/
echo "$0: Replacing manifests"
cp $tmp_dir/*.yaml $kube_dir/

rm -rf $tmp_dir

# Create CaaSP config dir
if [ ! -d "/etc/caasp" ]; then
    mkdir /etc/caasp
fi

# First time setup of user-configuration for salt-master
if [ ! -f "/etc/caasp/salt-master-custom.conf" ]; then
    echo "# Custom Configurations for Salt-Master" > /etc/caasp/salt-master-custom.conf
fi

# Migrate haproxy config path post path change
if [[ ! -f "/etc/caasp/haproxy/haproxy.cfg" && -f "/etc/haproxy/haproxy.cfg" ]]; then
    if [ ! -d "/etc/caasp/haproxy" ]; then
        mkdir /etc/caasp/haproxy
    fi

    mv /etc/haproxy/haproxy.cfg /etc/caasp/haproxy/haproxy.cfg

    # Add the Velum and Velum-API services to HAproxy
    cat << EOF >> /etc/caasp/haproxy/haproxy.cfg

listen velum
        bind 0.0.0.0:80
        bind 0.0.0.0:443 ssl crt /etc/pki/private/velum-bundle.pem ca-file /etc/pki/ca.crt
        mode http
        acl path_autoyast path_reg ^/autoyast$
        option forwardfor
        http-request set-header X-Forwarded-Proto https
        redirect scheme https code 302 if !{ ssl_fc } !path_autoyast
        default-server inter 10s fall 3
        balance roundrobin
        server velum unix@/var/run/puma/dashboard.sock

listen velum-api
        bind 127.0.0.1:443 ssl crt /etc/pki/private/velum-bundle.pem ca-file /etc/pki/ca.crt
        mode http
        option forwardfor
        http-request set-header X-Forwarded-Proto https
        default-server inter 10s fall 3
        balance roundrobin
        server velum unix@/var/run/puma/api.sock
EOF
fi

# Generate missing TLS bundle files
if [ ! -f "/etc/pki/private/velum-bundle.pem" ]; then
    cat /etc/pki/velum.crt /etc/pki/private/velum.key > /etc/pki/private/velum-bundle.pem
    chmod 600 /etc/pki/private/velum-bundle.pem
fi
if [ ! -f "/etc/pki/private/salt-api-bundle.pem" ]; then
    cat /etc/pki/salt-api.crt /etc/pki/private/salt-api.key > /etc/pki/private/salt-api-bundle.pem
    chmod 600 /etc/pki/private/salt-api-bundle.pem
fi
if [ ! -f "/etc/pki/private/ldap-bundle.pem" ]; then
    cat /etc/pki/ldap.crt /etc/pki/private/ldap.key > /etc/pki/private/ldap-bundle.pem
    chmod 600 /etc/pki/private/ldap-bundle.pem
fi

# Generate TLS CA and Initial Certificates
/usr/share/caasp-container-manifests/gen-certs.sh

# add an entry for ldap.infra.caasp.local to /etc/hosts
# this is needed to enable net-ldap to validate the certificate for LDAP_HOST
if ! [ "$(cat /etc/hosts | grep -E "^127.0.0.1\s+" | grep ldap.infra.caasp.local)" ]; then
    sed -i 's/127.0.0.1\tlocalhost/127.0.0.1\tlocalhost ldap.infra.caasp.local/g' /etc/hosts
fi

VELUM_CRT_FINGERPRINT_SHA1=$(openssl x509 -noout -in /etc/pki/velum.crt -fingerprint -sha1 | cut -d= -f2)
VELUM_CRT_FINGERPRINT_SHA256=$(openssl x509 -noout -in /etc/pki/velum.crt -fingerprint -sha256 | cut -d= -f2)

# Remove old /etc/issue.d/90-velum.conf to not have two files
test -f /etc/issue.d/90-velum.conf && rm -f /etc/issue.d/90-velum.conf
# Generate issue file with Velum details
# https://bugzilla.suse.com/show_bug.cgi?id=1031682
cat <<EOF > /run/issue.d/80-velum.conf

You can manage your cluster by opening the web application running on
port 443 of this node from your browser: https://<this-node>

You can also check that the instance you are accessing matches the
certificate fingerprints presented to your browser:

Velum SHA1 fingerprint:   $VELUM_CRT_FINGERPRINT_SHA1
Velum SHA256 fingerprint: $VELUM_CRT_FINGERPRINT_SHA256
EOF
# Call issue-generator to use the new issue.d snippet
/usr/sbin/issue-generator
