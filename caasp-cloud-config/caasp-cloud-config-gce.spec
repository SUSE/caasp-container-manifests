#
# spec file for package caasp-cloud-config-gce
#
# Copyright (c) 2017
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


Name:           caasp-cloud-config-gce
Version:        1.1.0
Release:        0
License:        MIT
Summary:        Configuration for CaaSP
URL:            http://www.github.com:SUSE/pubcloud
Group:          Productivity/Networking/Web/Servers
Source0:        %{name}-%{version}.tar.bz2
Provides:       caasp-cloud-config
Conflicts:      otherproviders(caasp-cloud-config)
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root

BuildArch:      noarch
BuildRequires:  salt
Requires:       salt

%description
Configuration for CaaSP set up and operation in the Public Cloud

%prep
%setup -q

%build

%install
make install-caasp-config DESTDIR=%{buildroot}
pushd %{buildroot}/etc/salt/pillar
mv gce.csp.sls cloud.sls
popd

%files
%defattr(-,root,root,-)
%config /etc/salt/pillar
/usr/share/caasp-cloud-config
