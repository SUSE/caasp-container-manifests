#!/usr/bin/env bash

umask 377

mkdir -p /salt-master-pki/minions/
temp_dir=`mktemp -d`

if [ ! -f /salt-admin-minion-pki/minion.pem ]; then
    salt-key -u root --gen-keys=admin --gen-keys-dir $temp_dir
    cp $temp_dir/admin.pub /salt-master-pki/minions/admin
    mv $temp_dir/admin.pub /salt-admin-minion-pki/minion.pub
    mv $temp_dir/admin.pem /salt-admin-minion-pki/minion.pem
fi

if [ ! -f /salt-ca-minion-pki/minion.pem ]; then
    salt-key -u root --gen-keys=ca --gen-keys-dir $temp_dir
    cp $temp_dir/ca.pub /salt-master-pki/minions/ca
    mv $temp_dir/ca.pub /salt-ca-minion-pki/minion.pub
    mv $temp_dir/ca.pem /salt-ca-minion-pki/minion.pem
fi

if [ ! -f /etc/pki/ca.crt ] || [ ! -f /etc/pki/public-ca.crt ] || [ ! -f /etc/pki/velum.crt ] || [ ! -f /etc/pki/salt-api.crt ]; then
    if [ ! -f /salt-init-certs-minion-pki/minion.pem ]; then
       salt-key -u root --gen-keys=cert-init --gen-keys-dir $temp_dir
       cp $temp_dir/cert-init.pub /salt-init-certs-minion-pki/minions/cert-init
       mv $temp_dir/cert-init.pub /salt-init-certs-minion-pki/minion.pub
       mv $temp_dir/cert-init.pem /salt-init-certs-minion-pki/minion.pem
    fi
fi

rm -rf $temp_dir
