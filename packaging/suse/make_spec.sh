#!/bin/bash

if [ -z "$1" ]; then
  cat <<EOF
usage:
  ./make_spec.sh PACKAGE
EOF
  exit 1
fi

cd $(dirname $0)

YEAR=$(date +%Y)
VERSION=$(cat ../../VERSION)
COMMIT_UNIX_TIME=$(git show -s --format=%ct)
VERSION="${VERSION%+*}+$(date -d @$COMMIT_UNIX_TIME +%Y%m%d).$(git rev-parse --short HEAD)"
NAME=$1

cat <<EOF > ${NAME}.spec
#
# spec file for package $NAME
#
# Copyright (c) $YEAR SUSE LINUX Products GmbH, Nuernberg, Germany.
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

Name:           $NAME
Version:        $VERSION
Release:        0
License:        Apache-2.0
Summary:        Manifest file templates for containers on controller node
Url:            https://github.com/kubic-project/caasp-container-manifests
Group:          System/Management
Source:         master.tar.gz
Requires:       container-feeder
# Require all the docker images
Requires:       sles12-pause-1.0.0-docker-image >= 1.0.0
Requires:       sles12-mariadb-10.0-docker-image >= 1.0.0
Requires:       sles12-pv-recycler-node-1.0.0-docker-image >= 1.0.0
Requires:       sles12-salt-api-2015.8.12-docker-image >= 1.0.0
Requires:       sles12-salt-master-2015.8.12-docker-image >= 1.0.0
Requires:       sles12-salt-minion-2015.8.12-docker-image >= 1.0.0
Requires:       sles12-velum-0.0-docker-image >= 1.0.0
# Require all  the things we mount from the host from the kubernetes-salt package
Requires:       kubernetes-salt
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
Manifest file templates will instruct kubelet service to bring up salt
and velum containers on a controller node.

%prep
%setup -q -n ${NAME}-master

%build

%install
for file in public.yaml private.yaml; do
  install -D -m 0644 \$file %{buildroot}/%{_datadir}/%{name}/\$file
done
install -D -m 0755 activate.sh %{buildroot}/%{_datadir}/%{name}/activate.sh
for dir in mysql salt/grains salt/minion.d-ca; do
  install -d %{buildroot}/%{_datadir}/%{name}/config/\$dir
  install config/\$dir/* %{buildroot}/%{_datadir}/%{name}/config/\$dir
done


%files
%defattr(-,root,root)
%doc LICENSE README.md
%dir %{_datadir}/%{name}
%{_datadir}/%{name}/*
EOF
