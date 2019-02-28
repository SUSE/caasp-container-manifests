#!/bin/bash
umask 377;

# wait until the file exists and has contents
while [ ! -s /infra-secrets/mariadb-root-password ]; do
    sleep 1
done

ENV=${ENV:-production}

# only allow chars valid in MariaDB idenfiers (letters, numbers, underscore)
shopt -s extglob
ENV=${ENV//@([^[:word:]])}
shopt -u extglob

if [ ! -f /infra-secrets/mariadb-velum-password ]; then
    head -n 10 /dev/random | base64 | head -n 10 | tail -n 1 > /infra-secrets/mariadb-velum-password
fi

if [ ! -f /infra-secrets/mariadb-salt-password ]; then
    head -n 10 /dev/random | base64 | head -n 10 | tail -n 1 > /infra-secrets/mariadb-salt-password
fi

root_passwd=`cat /infra-secrets/mariadb-root-password`
mysql_flags="-uroot -p$root_passwd"

while ! mysql $mysql_flags -e quit; do
    sleep 1
done

velum_passwd=`cat /infra-secrets/mariadb-velum-password`
salt_passwd=`cat /infra-secrets/mariadb-salt-password`

if [[ -z "${velum_passwd}" || -z "${salt_passwd}" ]]; then
    echo "Failed generating velum/salt passwords" >&2
    exit 1
fi

mysql $mysql_flags -f <<EOF
  CREATE SCHEMA IF NOT EXISTS velum_$ENV;
  CREATE USER IF NOT EXISTS velum@localhost;
  SET PASSWORD FOR          velum@localhost = PASSWORD( "$velum_passwd" );
  CREATE USER IF NOT EXISTS salt@localhost;
  SET PASSWORD FOR          salt@localhost = PASSWORD( "$salt_passwd" );
  GRANT ALL PRIVILEGES ON velum_$ENV.* TO velum@localhost;
  GRANT SELECT,INSERT,DELETE ON velum_$ENV.* TO salt@localhost;
  FLUSH PRIVILEGES;
EOF

exit 0
