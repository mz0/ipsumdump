# Warning: this file must be usable by regular make
# (unlike the Makefiles in subdirectories).

SHELL = /bin/bash


PACKAGE = ipsumdump
VERSION = 1.86
LIBCLICK_VERSION = 2.1
libclick = libclick-$(LIBCLICK_VERSION)

top_srcdir = .
srcdir = .
top_builddir = .
subdir = .
conf_auxdir = $(top_srcdir)/libclick-2.1

AUTOCONF = $(conf_auxdir)/missing autoconf
INSTALL = /usr/bin/install -c
INSTALL_IF_CHANGED = ${INSTALL} -C
INSTALL_DATA = /usr/bin/install -c -m 644
INSTALL_DATA_IF_CHANGED = ${INSTALL} -C -m 644
mkinstalldirs = $(conf_auxdir)/mkinstalldirs

prefix = /home/mz0/.local
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin
datarootdir = ${prefix}/share
mandir = ${datarootdir}/man

CLICK_BUILDTOOL = $(top_builddir)/libclick-2.1/click-buildtool
CLICKINCLUDES = -I$(top_builddir)/libclick-2.1/include -I$(top_srcdir)/libclick-2.1/include
CLICKLIB = $(top_builddir)/libclick-2.1/libsrc/libclick.a

all: libclick-2.1 src Makefile

$(libclick): always
	@cd $(libclick) && $(MAKE) all
src: $(libclick) always stamp-h
	@cd src && $(MAKE) all-local
ipsumdump: $(libclick) always stamp-h
	@cd src && $(MAKE) ipsumdump
ipaggcreate: $(libclick) always stamp-h
	@cd src && $(MAKE) ipaggcreate
ipaggmanip: $(libclick) always stamp-h
	@cd src && $(MAKE) ipaggmanip

install: always libclick-2.1 stamp-h
	@cd src && $(MAKE) install
	@$(MAKE) install-man
install-libclick: always
	@cd $(libclick) && $(MAKE) install
install-man: $(srcdir)/ipsumdump.1 $(srcdir)/ipaggcreate.1 $(srcdir)/ipaggmanip.1
	$(mkinstalldirs) $(mandir) $(DESTDIR)$(mandir)/man1
	$(INSTALL_DATA) $(srcdir)/ipsumdump.1 $(DESTDIR)$(mandir)/man1/ipsumdump.1
	$(INSTALL_DATA) $(srcdir)/ipaggcreate.1 $(DESTDIR)$(mandir)/man1/ipaggcreate.1
	$(INSTALL_DATA) $(srcdir)/ipaggmanip.1 $(DESTDIR)$(mandir)/man1/ipaggmanip.1

uninstall: always
	@cd src && $(MAKE) uninstall
	@$(MAKE) uninstall-man
uninstall-man: always
	-rm -f $(DESTDIR)$(mandir)/man1/ipsumdump.1
	-rm -f $(DESTDIR)$(mandir)/man1/ipaggcreate.1
	-rm -f $(DESTDIR)$(mandir)/man1/ipaggmanip.1

elemlist elemlists: always
	@cd src && $(MAKE) elemlist

$(srcdir)/ipsumdump.1: $(srcdir)/ipsumdump.pod
	pod2man --center ' ' --section 1 --release 'Version $(VERSION)' $(srcdir)/ipsumdump.pod > $(srcdir)/ipsumdump.1
	perl -ni -e 'print unless /^\.if n \.na$$/;' $(srcdir)/ipsumdump.1
$(srcdir)/ipaggcreate.1: $(srcdir)/ipaggcreate.pod
	pod2man --center ' ' --section 1 --release 'Version $(VERSION)' $(srcdir)/ipaggcreate.pod > $(srcdir)/ipaggcreate.1
	perl -ni -e 'print unless /^\.if n \.na$$/;' $(srcdir)/ipaggcreate.1
$(srcdir)/ipaggmanip.1: $(srcdir)/ipaggmanip.pod
	pod2man --center ' ' --section 1 --release 'Version $(VERSION)' $(srcdir)/ipaggmanip.pod > $(srcdir)/ipaggmanip.1
	perl -ni -e 'print unless /^\.if n \.na$$/;' $(srcdir)/ipaggmanip.1
always:
	@:

$(srcdir)/configure: $(srcdir)/configure.ac
	cd $(srcdir) && $(AUTOCONF)
config.status: $(srcdir)/configure
	$(SHELL) $(srcdir)/configure  '--prefix=/home/mz0/.local' '--enable-ip6' '--enable-nanotimestamp'
Makefile: config.status $(srcdir)/Makefile.in
	cd $(top_builddir) && $(SHELL) ./config.status Makefile
config.h: stamp-h
stamp-h: $(srcdir)/config.h.in config.status
	cd $(top_builddir) && $(SHELL) ./config.status config.h

clean:
	@-for d in $(libclick) src; do (cd $$d && $(MAKE) clean); done
	-rm -f conftest.*
distclean:
	@-for d in $(libclick) src; do (cd $$d && $(MAKE) distclean); done
	-rm -f config.h Makefile config.status
	-rm -f config.cache config.log stamp-h


clicksrcdir = 
clickbuilddir = NONE
fetch-click:
	@[ $(clickbuilddir) != NONE ] || (echo "Reconfigure with --with-click-build!"; exit 1)
	cd $(top_srcdir); sh ./bootstrap.sh "$(clickbuilddir)"


distdir = $(PACKAGE)-$(VERSION)
dist: $(distdir).tar.gz
	-rm -rf $(distdir)
$(distdir).tar.gz: always distdir
	tar czf $(distdir).tar.gz $(distdir)
distdir: $(srcdir)/configure
	-rm -rf $(distdir)
	mkdir $(distdir)
	@-chmod 777 $(distdir)
	$(MAKE) $(srcdir)/ipsumdump.1 $(srcdir)/ipaggcreate.1 $(srcdir)/ipaggmanip.1
	@echo Copying files...
	@for file in `cat $(srcdir)/DISTFILES`; do \
	  d=$(srcdir); \
	  if test -d "$$d/$$file"; then \
	    mkdir $(distdir)/$$file; \
	    chmod 777 $(distdir)/$$file; \
	  else \
	    test -f "$(distdir)/$$file" \
	    || ln $$d/$$file $(distdir)/$$file 2> /dev/null \
	    || cp -p $$d/$$file $(distdir)/$$file \
	    || echo "Could not copy $$d/$$file!" 1>&2; \
	  fi; \
	done
	@for fgroup in `cat $(top_srcdir)/CLICKFILES`; do \
	  fgroup=`echo "$$fgroup" | sed 's/:.*//'`; \
	  g=`echo $$fgroup | sed 's/.*\/\([^/]*\)$$/src\/\1/'`; \
	  for file in `cd $(top_srcdir) && eval echo $$g`; do \
	    ln $(top_srcdir)/$$file $(distdir)/src/$$file 2> /dev/null \
	    || cp -p $(top_srcdir)/$$file $(distdir)/$$file \
	    || echo "Could not copy $(top_srcdir)/$$file!" 1>&2; \
	  done; \
	done
	@cd $(libclick) && $(MAKE) distdir
	mv $(libclick)/`echo $(libclick) | sed 's/rc[0-9]*//'` $(distdir)/$(libclick)


.PHONY: all always $(libclick) src ipsumdump ipaggcreate ipaggmanip \
	elemlist elemlists \
	clean distclean dist distdir \
	install install-man uninstall uninstall-man \
	fetch-click
