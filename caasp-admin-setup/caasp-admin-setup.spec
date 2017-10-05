#
# spec file for package caasp-admin-setup
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


Name:           caasp-admin-setup
Version:        1.0.0
Release:        0
License:        MIT
Summary:        Setup the CaaSP Admin Node
URL:            http://www.github.com:SUSE/pubcloud
Group:          Productivity/Networking/Web/Servers
Source0:        %{name}-%{version}.tar.bz2
Requires:       caasp-cloud-config
Requires:       python3
Requires:       python3-docker
Requires:       python3-docopt
Requires:       python3-netifaces
Requires:       python3-PyYAML
Requires:       python3-pyOpenSSL
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root

BuildArch:      noarch

%description
Basic setup of the Admin node for a CaaSP cluster

%prep
%setup -q

%build

%install
make install DESTDIR=%{buildroot}

%files
%defattr(-,root,root,-)
%doc LICENSE
%{_sbindir}/caasp-admin-setup
