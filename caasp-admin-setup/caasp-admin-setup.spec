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
Version:        1.3.0
Release:        0
License:        MIT
Summary:        Setup the CaaSP Admin Node
URL:            http://www.github.com/SUSE/pubcloud
Group:          Productivity/Networking/Web/Servers
Source0:        %{name}-%{version}.tar.bz2
Requires:       caasp-cloud-config
Requires:       python
Requires:       python-docker-py
Requires:       python-docopt
Requires:       python-future
Requires:       python-netifaces
Requires:       python-pyOpenSSL
Requires:       python-susepubliccloudinfo
BuildRequires:  python
BuildRequires:  python-setuptools
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root

BuildArch:      noarch

%description
Basic setup of the Admin node for a CaaSP cluster

%prep
%setup -q

%build

%install
python setup.py install --prefix=%{_prefix} --root=%{buildroot}

# we want the script in /usr/sbin since it's admin use only, but
# setuptools do not support installing into /usr/sbin
mv %{buildroot}%{_bindir} %{buildroot}%{_sbindir}


%files
%defattr(-,root,root,-)
%doc LICENSE
%{_sbindir}/caasp-admin-setup
%{python_sitelib}/caasp_admin_setup-%{version}-py%{py_ver}.egg-info
%{python_sitelib}/caaspadminsetup
