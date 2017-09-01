#!/bin/sh

echo "master: IP_ADDRESS_OF_ADMIN_NODE" > /etc/salt/minion.d/master.conf
systemctl enable salt-minion
systemctl start salt-minion
