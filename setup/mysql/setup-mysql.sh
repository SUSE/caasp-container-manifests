#!/usr/bin/env bash
umask 377;

while [ ! -f /infra-secrets/mariadb-root-password ]; do
    sleep 1
done

ENV=${ENV:-production}

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

# Create both the ENV and the test databases.
# This is requird to run the test suites inside of devenv
mysql $mysql_flags -f <<EOF
  CREATE SCHEMA IF NOT EXISTS velum_$ENV;
  CREATE SCHEMA IF NOT EXISTS velum_test;
  CREATE USER velum@localhost IDENTIFIED BY "$velum_passwd";
  CREATE USER salt@localhost IDENTIFIED BY "$salt_passwd";
  GRANT ALL PRIVILEGES ON velum_$ENV.* TO velum@localhost;
  GRANT ALL PRIVILEGES ON velum_test.* TO velum@localhost;
  GRANT SELECT,INSERT,DELETE ON velum_$ENV.* TO salt@localhost;
  FLUSH PRIVILEGES;
EOF

exit 0
