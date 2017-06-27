#!/usr/bin/env bash

if [ -f /etc/pki/ca.crt ] && [ -f /etc/pki/public-ca.crt ] && [ -f /etc/pki/velum.crt ] &&
   [ -f /etc/pki/salt-api.crt ]; then
    # The certificates have already been initialized, nothing else to do here.
    exit 0
fi

while [ ! -f /salt-init-certs-minion-pki/minion.pem ]; do
    sleep 1
done

salt-call event.send 'salt/cert_init'
