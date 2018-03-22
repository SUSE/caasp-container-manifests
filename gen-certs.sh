#!/bin/bash

set -e

CACN=${CACN:-CaaSP Internal CA}
ORG=${ORG:-SUSE Autogenerated}
ORGUNIT=${ORGUNIT:-CaaSP $(uuidgen -r)}
CITY=${CITY:-Nuremberg}
STATE=${STATE:-Bavaria}
COUNTRY=${COUNTRY:-DE}

DIR="/etc/pki"
CERTS="$DIR/_certs"
PRIVATEDIR="$DIR/private"
WORK="$DIR/_work"

genca() {
    [ -f $PRIVATEDIR/ca.key ] && [ -f $DIR/ca.crt ] && return

    echo "Generating CA Certificate"

    mkdir -p $WORK
    mkdir -p $CERTS
    mkdir -p -m 700 $PRIVATEDIR

    # generate the CA _work key
    (umask 377 && openssl genrsa -out $PRIVATEDIR/ca.key 4096)

    cat > $WORK/ca.cfg <<EOF
[ca]
default_ca = CA_default

[CA_default]
dir = $DIR
certs	= \$dir
database = $WORK/index.txt
new_certs_dir	= $CERTS

certificate	= \$dir/ca.crt
serial = $WORK/serial
private_key	= $PRIVATEDIR/ca.key
RANDFILE = \$dir/.rand

default_days = 365
default_md = default
preserve = false
copy_extensions = copy

policy          = policy_match

[ policy_match ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = $COUNTRY
ST = $STATE
L = $CITY
O = $ORG
OU = $ORGUNIT
CN = $CACN

[v3_ca]
# Extensions to add to a CA certificate request
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
basicConstraints = critical, CA:TRUE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment, keyCertSign

[v3_req]
# Extensions to add to a server certificate request
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
EOF

    rm -f $WORK/index.txt $WORK/index.txt.attr
    touch $WORK/index.txt $WORK/index.txt.attr
    echo 1000 > $WORK/serial

    openssl req -batch -config $WORK/ca.cfg -sha256 -new -x509 -days 3650 -extensions v3_ca -key $PRIVATEDIR/ca.key -out $DIR/ca.crt
}

gencert() {
    [ -f $PRIVATEDIR/$1.key ] && [ -f $DIR/$1.crt ] && return

    echo "Generating $1 Certificate"

    # generate the server cert
    (umask 377 && openssl genrsa -out $PRIVATEDIR/$1.key 2048)

    cat > $WORK/$1.cfg <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = $COUNTRY
ST = $STATE
L = $CITY
O = $ORG
OU = $ORGUNIT
CN = $2

[v3_req]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
EOF

    count=0
    for dnsalt in $3
    do
        count=$((count + 1))
        echo "DNS.${count} = ${dnsalt}" >> $WORK/$1.cfg
    done

    count=0
    for ipalt in $4
    do
        count=$((count + 1))
        echo "IP.${count} = ${ipalt}" >> $WORK/$1.cfg
    done

    # generate the server csr
    openssl req -batch -config $WORK/$1.cfg -new -sha256 -nodes -extensions v3_req -key $PRIVATEDIR/$1.key -out $WORK/$1.csr

    # sign the server cert
    openssl ca -batch -config $WORK/ca.cfg -extensions v3_req -notext -in $WORK/$1.csr -out $DIR/$1.crt

    # final verification
    openssl verify -CAfile $DIR/ca.crt $DIR/$1.crt

    cat $DIR/$1.crt $PRIVATEDIR/$1.key > $PRIVATEDIR/$1-bundle.pem
    chmod 600 $PRIVATEDIR/$1-bundle.pem
}

ip_addresses() {
    ip address show | grep -Po 'inet \K[\d.]+' | grep -v '127.0.0.1' | tr '\n' ' '
}

all_hostnames=$(echo "$(hostname) $(hostname --fqdn) $(hostnamectl --transient) $(hostnamectl --static) \
                      $(cat /etc/hostname)" | tr ' ' '\n' | sort -u | tr '\n' ' ')

set -e
genca
gencert "velum" "Velum" "$all_hostnames" "$(ip_addresses)"
gencert "salt-api" "salt-api.infra.caasp.local" "" "127.0.0.1"
gencert "ldap" "OpenLDAP" "ldap.infra.caasp.local" "$(ip_addresses)"
