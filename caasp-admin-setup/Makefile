DESTDIR=
ver = $(shell rpm -q --specfile --qf '%{NAME}-%{VERSION}\n' caasp-admin-setup.spec)

tar:
	mkdir -p "$(ver)/usr/sbin"
	cp license_MIT.txt "$(ver)/LICENSE"
	cp Makefile "$(ver)"
	tar -cjf "$(ver).tar.bz2" "$(ver)"
	rm -rf "$(ver)"

install:
	mkdir -p "$(DESTDIR)/usr/sbin"
	cp /usr/sbin/* "$(DESTDIR)"
