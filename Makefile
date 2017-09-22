DESTDIR=
verAzure = $(shell rpm -q --specfile --qf '%{NAME}-%{VERSION}\n' caasp-cloud-config-azure.spec)
verEC2 = $(shell rpm -q --specfile --qf '%{NAME}-%{VERSION}\n' caasp-cloud-config-ec2.spec)
verGCE = $(shell rpm -q --specfile --qf '%{NAME}-%{VERSION}\n' caasp-cloud-config-gce.spec)

tar-azure-config:
	mkdir -p "$(verAzure)/etc"
	cp license_MIT.txt "$(verAzure)/LICENSE"
	cp Makefile "$(verAzure)"
	cp etc/*azure* "$(verAzure)/etc"
	tar -cjf "$(verAzure).tar.bz2" "$(verAzure)"
	rm -rf "$(verAzure)"

tar-ec2-config:
	mkdir -p "$(verEC2)/etc"
	cp license_MIT.txt "$(verEC2)/LICENSE"
	cp Makefile "$(verEC2)"
	cp etc/*ec2* "$(verEC2)/etc"
	tar -cjf "$(verEC2).tar.bz2" "$(verEC2)"
	rm -rf "$(verEC2)"

tar-gce-config:
	mkdir -p "$(verGCE)/etc"
	cp license_MIT.txt "$(verGCE)/LICENSE"
	cp Makefile "$(verGCE)"
	cp etc/*gce* "$(verGCE)/etc"
	tar -cjf "$(verGCE).tar.bz2" "$(verGCE)"
	rm -rf "$(verGCE)"

install-caasp-config:
	mkdir -p "$(DESTDIR)/etc"
	cp etc/* "$(DESTDIR)/etc"
