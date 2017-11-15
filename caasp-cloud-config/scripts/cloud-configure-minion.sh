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
    "-n"|"--help")
      echo "Usage: $0 [-c salt-cloud-deploy-dir] [-k]"
      echo
      echo "-k  keep deploy directory"
      exit 0
    ;;
    "-c")
      test -z "$2" && die "-n requires an argument"
      DEPLOY_DIR="$2"
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

echo "Temp depoly conf dir: ${DEPLOY_DIR}"
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

test -z "$KEEP_DEPLOY_DIR" && rm -rf "$DEPLOY_DIR"

exit 0
