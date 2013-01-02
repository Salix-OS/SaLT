PACKAGE = generate
POFILES = $(wildcard po/*.po)
MOFILES = $(POFILES:.po=.mo)
POTFILE = po/$(PACKAGE).pot
LOCALEDIR = locale

help:
	@echo "Help:"
	@echo "  build        build the .mo files"
	@echo "  all          build"
	@echo "  install      all + install them in ${LOCALEDIR}/"
	@echo "  clean        remove all .mo and .po~ files"
	@echo "  uninstall    remove what has been installed in ${LOCALEDIR}/"
	@echo "  clean-all    remove all generated and installed files"
	@echo "  udatetrans   update ${POTFILE} from ${PACKAGE} and generate/update .po files"

all: build

build: $(MOFILES)

%.mo : %.po
	@echo "Compiling $<"
	msgfmt $< -o $@

install: all
	make installmo

installmo:
	for j in $(MOFILES); do \
		install -d -m 755 \
			$(LOCALEDIR)/`basename $$j|sed "s/.mo//"`/LC_MESSAGES 2> /dev/null; \
		install -m 644 $$j \
			$(LOCALEDIR)/`basename $$j|sed "s/.mo//"`/LC_MESSAGES/$(PACKAGE).mo; \
	done

clean:
	@rm -f $(MOFILES)
	@rm -f $(POFILES:.po=.po~)

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
		--add-comments=\# \
		-o $(POTFILE) \
		$(PACKAGE)
	for i in $(POFILES); do \
		msgmerge -NU $$i $(POTFILE); \
	done

.PHONY: clean uninstall clean-all install installmo updatetrans build all help
