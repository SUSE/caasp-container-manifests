#!/bin/bash

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

# remove client generated salt minion ID
rm -f "${SALT_DIR}/minion.d/minion_id.conf"

systemctl enable salt-minion.service || die "Error enabling salt-minion"
systemctl start salt-minion.service || die "Error starting salt-minion"

test -z "$KEEP_DEPLOY_DIR" && rm -rf "$DEPLOY_DIR"

exit 0
