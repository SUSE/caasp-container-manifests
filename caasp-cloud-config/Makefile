DESTDIR=
verAzure = $(shell rpm -q --specfile --qf '%{NAME}-%{VERSION}\n' caasp-cloud-config-azure.spec)
verEC2 = $(shell rpm -q --specfile --qf '%{NAME}-%{VERSION}\n' caasp-cloud-config-ec2.spec)
verGCE = $(shell rpm -q --specfile --qf '%{NAME}-%{VERSION}\n' caasp-cloud-config-gce.spec)

tar-azure-config:
	mkdir -p "$(verAzure)/srv/pillar"
	cp license_MIT.txt "$(verAzure)/LICENSE"
	cp Makefile "$(verAzure)"
	cp srv/pillar/*azure* srv/pillar/top.sls "$(verAzure)/srv/pillar"
	cp -r salt-master.d scripts "$(verAzure)"
	tar -cjf "$(verAzure).tar.bz2" "$(verAzure)"
	rm -rf "$(verAzure)"

tar-ec2-config:
	mkdir -p "$(verEC2)/srv/pillar"
	mkdir -p "$(verEC2)/usr/share/caasp-cloud-config"
	cp license_MIT.txt "$(verEC2)/LICENSE"
	cp Makefile "$(verEC2)"
	cp srv/pillar/*ec2* srv/pillar/top.sls "$(verEC2)/srv/pillar"
	cp -r salt-master.d scripts "$(verEC2)/"
	tar -cjf "$(verEC2).tar.bz2" "$(verEC2)"
	rm -rf "$(verEC2)"

tar-gce-config:
	mkdir -p "$(verGCE)/srv/pillar"
	mkdir -p "$(verGCE)/usr/share/caasp-cloud-config"
	cp license_MIT.txt "$(verGCE)/LICENSE"
	cp Makefile "$(verGCE)"
	cp srv/pillar/*gce* srv/pillar/top.sls "$(verGCE)/srv/pillar"
	cp -r salt-master.d scripts "$(verGCE)"
	tar -cjf "$(verGCE).tar.bz2" "$(verGCE)"
	rm -rf "$(verGCE)"

install-caasp-config:
	mkdir -p "$(DESTDIR)/srv/pillar"
	mkdir -p "$(DESTDIR)/usr/share/caasp-cloud-config"
	cp srv/pillar/* "$(DESTDIR)/srv/pillar"
	cp -r salt-master.d "$(DESTDIR)/usr/share/caasp-cloud-config"
	cp scripts/cloud-configure-minion.sh "$(DESTDIR)/usr/share/caasp-cloud-config"
