#!/bin/bash

if [ -z "$1" ]; then
  cat <<EOF
usage:
  ./make_spec.sh PACKAGE [BRANCH]
EOF
  exit 1
fi

cd $(dirname $0)

YEAR=$(date +%Y)
VERSION=$(cat ../../VERSION)
REVISION=$(git rev-list HEAD | wc -l)
COMMIT=$(git rev-parse --short HEAD)
VERSION="${VERSION%+*}+git_r${REVISION}_${COMMIT}"
NAME=$1
BRANCH=${2:-master}
SAFE_BRANCH=${BRANCH//\//-}

cat <<EOF > ${NAME}.spec
#
# spec file for package $NAME
#
# Copyright (c) $YEAR SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

%if 0%{?suse_version} == 1315 && !0%{?is_opensuse}
  %define _base_image sles12
%endif

%if 0%{?suse_version} == 1500 && !0%{?is_opensuse}
  %define _base_image sles15
%endif

%if 0%{?is_opensuse} && 0%{?suse_version} > 1500
  %define _base_image tumbleweed
%endif

Name:           $NAME
Version:        $VERSION
Release:        0
License:        Apache-2.0
Summary:        Manifest file templates for containers on controller node
Url:            https://github.com/kubic-project/caasp-container-manifests
Group:          System/Management
Source:         ${SAFE_BRANCH}.tar.gz
Requires:       container-feeder
# Require all the docker images
Requires:       %{_base_image}-pause-image >= 2.0.0
Requires:       %{_base_image}-mariadb-image >= 2.0.0
Requires:       %{_base_image}-pv-recycler-node-image >= 2.0.0
Requires:       %{_base_image}-salt-api-image >= 2.0.0
Requires:       %{_base_image}-salt-master-image >= 2.0.0
Requires:       %{_base_image}-salt-minion-image >= 2.0.0
Requires:       %{_base_image}-velum-image >= 2.0.0
Requires:       %{_base_image}-haproxy-image >= 2.0.0
Requires:       %{_base_image}-flannel-image >= 2.0.0
Requires:       %{_base_image}-dnsmasq-nanny-image >= 2.0.0
Requires:       %{_base_image}-kubedns-image >= 2.0.0
Requires:       %{_base_image}-sidecar-image >= 2.0.0
Requires:       %{_base_image}-tiller-image >= 2.0.0
Requires:       %{_base_image}-openldap-image >= 2.0.0
Requires:       %{_base_image}-caasp-dex-image >= 2.0.0
# Require all  the things we mount from the host from the kubernetes-salt package
Requires:       kubernetes-salt
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
%if ! 0%{?is_susecaasp}
# caasp-tools package provides %{_datadir}/caasp-container-manifests/activate.sh
# if this is not building for SUSE CaaSP, so both packages can't be installed
# at the same time.
Conflicts:      caasp-tools
%endif

%description
Manifest file templates will instruct kubelet service to bring up salt
and velum containers on a controller node.

%prep
%setup -q -n ${NAME}-${SAFE_BRANCH}

%build

%install
for file in manifests/*.yaml; do
  install -D -m 0644 \$file %{buildroot}/%{_datadir}/%{name}/\$file
  # fix image name
  sed -e "s%image:[ ]*sles12/\(.*\):%image: %{_base_image}/\1:%g" -i %{buildroot}/%{_datadir}/%{name}/\$file
done
install -D -m 0755 config/haproxy/haproxy.cfg %{buildroot}/etc/haproxy/haproxy.cfg
install -D -m 0755 activate.sh %{buildroot}/%{_datadir}/%{name}/activate.sh
install -D -m 0755 gen-certs.sh %{buildroot}/%{_datadir}/%{name}/gen-certs.sh
for dir in mysql salt/grains salt/minion.d-ca; do
  install -d %{buildroot}/%{_datadir}/%{name}/config/\$dir
  install config/\$dir/* %{buildroot}/%{_datadir}/%{name}/config/\$dir
done
cp -R setup %{buildroot}/%{_datadir}/%{name}

# Install service
install -D -m 0755 admin-node-setup.sh %{buildroot}/%{_datadir}/%{name}/admin-node-setup.sh
mkdir -p %{buildroot}/%{_unitdir}
install -D -m 0644 admin-node-setup.service %{buildroot}/%{_unitdir}/
sed -e "s#__ADMIN_NODE_SETUP_PATH__#%{_datadir}/%{name}#" -i %{buildroot}/%{_unitdir}/admin-node-setup.service
mkdir -p %{buildroot}/%{_sbindir}
ln -s %{_sbindir}/service %{buildroot}/%{_sbindir}/rcadmin-node-setup

%pre
%service_add_pre admin-node-setup.service

%post
%service_add_post admin-node-setup.service

%preun
%service_del_preun admin-node-setup.service

%postun
%service_del_postun admin-node-setup.service

%files
%defattr(-,root,root)
%doc LICENSE README.md
%dir %{_datadir}/%{name}
%dir %{_datadir}/%{name}/manifests
%dir /etc/haproxy
%config(noreplace) /etc/haproxy/haproxy.cfg
%{_sbindir}/rcadmin-node-setup
%{_unitdir}/admin-node-setup.service
%{_datadir}/%{name}/*
%changelog
EOF
