#!/bin/bash

set -e

ADMIN_EMAIL="root@localhost"

show_usage()
{
  echo "Usage: $0 [-e admin_email] [-p admin_password]"
  echo
  echo "Default admin_email is \"$ADMIN_EMAIL\""
  echo "Default admin password is the instance ID"
}

get_ip_address()
{
  ip -4 a list dev eth0 | while read a b rest; do
    if [ "$a" == "inet" ]; then
      echo "${b%%/*}"
      break
    fi
  done
}

while [ -n "$1" ]; do
  case "$1" in
    "-h|--help")
      show_usage
      exit 0
      ;;
    "-e")
      test -z "$2" && { echo "-e needs an argument" >&2 ; exit 1 ; }
      ADMIN_EMAIL="$2"
      shift
      ;;
    "-p")
      test -z "$2" && { echo "-p needs an argument" >&2 ; exit 1 ; }
      ADMIN_PASSWORD="$2"
      shift
      ;;
    *)
      show_usage
      exit 1
      ;;
  esac
  shift
done
      
ADDR=$(get_ip_address)
test -z "$ADDR" && { echo "Coud not get local IP address" >&2 ; exit 1 ; }

# newer etcd does seem to need this set
sed -i -r -e "s,#?ETCD_INITIAL_ADVERTISE_PEER_URLS=\"[^\"]*\",ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http://${ADDR}:2380\"," /etc/sysconfig/etcd
sed -i -r -e "s,#?ETCD_INITIAL_CLUSTER=\"[^\"]*\",ETCD_INITIAL_CLUSTER=\"default=http://${ADDR}:2380\"," /etc/sysconfig/etcd

# run caasp activate script
/usr/share/caasp-container-manifests/activate.sh

echo "Starting etcd service"
systemctl enable etcd.service
systemctl start etcd.service

echo "Starting kubelet service"
systemctl enable kubelet.service
systemctl start kubelet.service

echo -n "Waiting for velum container to start "
attempt=0
while true ; do
  CID="$(docker ps | grep velum-dashboard | cut -f1 -d' ')"
  [ -n "$CID" ] && break
  if [ $attempt -lt 600 ]; then
    attempt=$((attempt+1))
    test $((attempt%10)) -eq 0 && echo -n "."
    sleep 1
  else
    echo
    echo "Timeout waiting for velum container to start" >&2
    exit 1
  fi
done
echo
  
test -z "ADMIN_PASSWORD" && ADMIN_PASSWORD="$(ec2metadata | grep instance-id | cut -f2 -d' ')"
 
if [ -z "$ADMIN_PASSWORD" ]; then
  echo "Could not get instance ID" 2>&1
  exit 1
fi

# The velum container is up, but the data base might not be ready yet
CMD="bundle exec rails runner bin/check_db.rb"
attempt=0
while true ; do
  db_status=$(docker exec -it $CID bash -c "VELUM_DB_PASSWORD=\"$(cat /var/lib/misc/infra-secrets/mariadb-velum-password)\" ${CMD}")
  # db_status may have a trailing \r
  [[ "$db_status" =~ "DB_READY" ]] && break
  if [ $attempt -lt 30 ]; then
    attempt=$((attempt+1))
    sleep 1
  else
    echo "Velum data base is not up" >&2
    exit 1
  fi
done

echo "Creating admin account"
CMD="bundle exec rails runner \"User.create(email: \\\"${ADMIN_EMAIL}\\\", password: \\\"${ADMIN_PASSWORD}\\\")\""
docker exec -it $CID bash -c "VELUM_DB_PASSWORD=\"$(cat /var/lib/misc/infra-secrets/mariadb-velum-password)\" ${CMD}"

echo "Admin user created."
echo "Admin email:    $ADMIN_EMAIL"
echo "Admin password: $ADMIN_PASSWORD"

exit 0
