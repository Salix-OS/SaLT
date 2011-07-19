PACKAGE = genlocale
POTPLFILES = $(wildcard po/tpl/*.po)
POFILES = $(wildcard po/*.po)
MOFILES = $(POFILES:.po=.mo)
POTFILE = po/$(PACKAGE).pot
LOCALEDIR = locale
VOLUMENAME = VolumeName

help:
	@echo "Help:"
	@echo "  build        build the .mo files"
	@echo "  compiletpl   compile the template po files using ${VOLUMENAME}"
	@echo "  all          compiletpl + build"
	@echo "  install      all + install them in ${LOCALEDIR}/"
	@echo "  clean        remove all .mo, .po and tpl/.po~ files"
	@echo "  uninstall    remove what has been installed in ${LOCALEDIR}/"
	@echo "  clean-all    remove all generated and installed files"
	@echo "  udatetrans   update ${POTFILE} from ${PACKAGE} and generage/update .po.tpl files"

build: $(MOFILES)

%.mo : %.po
	@echo "Compiling $<"
	msgfmt -f $< -o $@

compiletpl:
	for i in ${POTPLFILES}; do \
		po=po/$$(basename "$$i" .tpl); \
		sed "s/_DISTRONAME_/${VOLUMENAME}/" "$$i" > "$$po"; \
	done

all: compiletpl
	make build

install: all
	make installmo

installmo:
	for j in $(MOFILES); do \
		install -d -m 755 \
			$(LOCALEDIR)/`basename $$j|sed "s/.mo//"`/LC_MESSAGES \
			2> /dev/null; \
		install -m 644 $$j \
			$(LOCALEDIR)/`basename $$j|sed "s/.mo//"`/LC_MESSAGES/$(PACKAGE).mo; \
	done

clean:
	@rm -f $(MOFILES)
	@rm -f $(POFILES)
	@rm -f $(POTPLFILES:.po=.po~)

uninstall:
	@rm -f $(LOCALEDIR)/*/LC_MESSAGES/$(PACKAGE).mo
	@rmdir -p $(LOCALEDIR)/*/LC_MESSAGES/ 2>/dev/null || true

clean-all: clean uninstall
	@rm -rf $(LOCALEDIR)

updatetrans:
	@touch $(POTFILE)
	xgettext --from-code=utf-8 \
		-j \
		-L Python \
		-o $(POTFILE) \
		$(PACKAGE)
	for i in $(POTPLFILES); do \
		msgmerge -U $$i $(POTFILE); \
	done

.PHONY: clean uninstall clean-all install installmo updatetrans build compiletpl all help
