#!/bin/bash

# COPYRIGHT 2017 SUSE Linux GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

SALT_DIR=/etc/salt
PKI_DIR="${SALT_DIR}/pki/minion"
SUSECONNECT_OPTS=

die()
{
  test -n "$1" && echo "$@" >&2
  if [ -n "$DEPLOY_DIR" -a -z "$KEEP_DEPLOY_DIR" ]; then
    rm -rf "$KEEP_DEPLOY_DIR"
  fi
  exit 1
}

while [ -n "$1" ]; do
  case "$1" in
    "-h"|"--help")
      echo "Usage: $0 [-c salt-cloud-deploy-dir] [-k] [-u username] [-s ssh_key_data]"
      echo
      echo "-k  keep deploy directory"
      exit 0
    ;;
    "-c")
      test -z "$2" && die "-c requires an argument"
      DEPLOY_DIR="$2"
      shift
    ;;
    "-u")
      test -z "$2" && die "-u requires an argument"
      SSH_USER="$2"
      shift
    ;;
    "-s")
      test -z "$2" && die "-s requires an argument"
      SSH_KEY="$2"
      shift
    ;;
    "-k")
      KEEP_DEPLOY_DIR=yes
    ;;
  esac
  shift
done

if [ -z "$DEPLOY_DIR" ]; then
  DEPLOY_DIR="$(dirname $0)"
fi

exec 1> >(tee "${DEPLOY_DIR}/log")
exec 2>&1

echo "Minion boostrap running."

echo "Temp deploy conf dir: ${DEPLOY_DIR}"
ls -l ${DEPLOY_DIR}

if [ -f "${DEPLOY_DIR}/minion" ]; then
  cp "${DEPLOY_DIR}/minion" ${SALT_DIR}/minion || die "Error coopying minion config"
else
  die "No minion configuration in deploy directory"
fi

mkdir -p "${PKI_DIR}"
if [ -f "${DEPLOY_DIR}/minion.pem" ]; then
  cp "${DEPLOY_DIR}/minion.pem" "${PKI_DIR}" || die "Error coopying minion key"
  chmod 600 "${PKI_DIR}/minion.pem"
else
  die "No minion private key in deploy directory"
fi

if [ -f "${DEPLOY_DIR}/minion.pub" ]; then
  cp "${DEPLOY_DIR}/minion.pub" "${PKI_DIR}" || die "Error coopying minion public key"
else
  die "No minion public key in deploy directory"
fi

# NOTE: the minion configuration passed by salt-cloud is monolithic and
# contains the minion ID in /etc/salt/minion. SLES automatically initializes
# the minion ID on boot, which we need to prevent.
#
# remove client generated salt minion ID
rm -f "${SALT_DIR}/minion.d/minion_id.conf"
# this prevents it from being re-generated at boot
systemctl disable setup-salt-minion.service

systemctl enable salt-minion.service || die "Error enabling salt-minion"
systemctl start salt-minion.service || die "Error starting salt-minion"

# for user convenience, assess to the nodes should be possible using
# the same credentials regardless of which cloud framework is being used
current_user=`logname`
if [ -n "$SSH_USER" -a "$SSH_USER" != "$current_user" ]; then
  # we may need to set up SSH_USER as a new sudo enabled user
  if ! id -u "$SSH_USER" 2>/dev/null ; then
    useradd -m "$SSH_USER" && echo "User $SSH_USER created"
    echo "$SSH_USER ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/caasp-admin
    if [ -z "$SSH_KEY" ]; then
      # new user created but no key provided, use current user's authorized
      # keys
      eval home_dir="~${SSH_USER}"
      mkdir -p "${home_dir}/.ssh"
      eval src_auth_keys_file="~${current_user}/.ssh/authorized_keys"
      cp $src_auth_keys_file "${home_dir}/.ssh/authorized_keys" && \
        echo "Added authorized keys of ${current_user} for ${SSH_USER}"
      chown "$SSH_USER":users "${home_dir}/.ssh/authorized_keys"
      chmod 600 "${home_dir}/.ssh/authorized_keys"
    fi
  fi
fi
# add provided ssh key, if any
if [ -n "$SSH_KEY" ]; then
  target_user="$SSH_USER"
  test -z "$target_user" && target_user="$current_user"
  eval home_dir="~$target_user"
  mkdir -p "${home_dir}/.ssh"
  auth_keys_file="${home_dir}/.ssh/authorized_keys"
  grep -q "$SSH_KEY" "$auth_keys_file" 2>/dev/null || \
    echo "$SSH_KEY" >> "$auth_keys_file"
  echo "Added provided public key to ${auth_keys_file}"
  chown "$target_user":users ${auth_keys_file}
  chmod 600 ${auth_keys_file}
fi

# Attempt SCC registration
if [ -n "$SUSECONNECT_OPTS" ]; then
  eval SUSEConnect "$SUSECONNECT_OPTS" || die "Could not register with SCC"
fi

test -z "$KEEP_DEPLOY_DIR" && rm -rf "$DEPLOY_DIR"

exit 0
