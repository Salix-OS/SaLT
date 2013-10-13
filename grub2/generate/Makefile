PACKAGE = salt
SRCFILES = $(sort $(wildcard ../build/boot/grub/*.cfg *.cfg.tpl))
POFILES = $(sort $(wildcard po/*.po))
MOFILES = $(POFILES:.po=.mo.gz)
POTFILE = po/$(PACKAGE).pot

help:
	@echo "Help:"
	@echo "  build        build the .mo files"
	@echo "  clean        remove all .mo and .po~ files"
	@echo "  updatepot    update ${POTFILE} from *.cfg and generate/update po/*.po files"
	@echo "  all          updatepot + build"

all: updatepot build

build: $(MOFILES)

%.mo.gz: %.po
	@echo "Compiling $<"
	$(shell sh ./pohelper $<)
	@gzip -9 -v $*.mo

clean:
	@rm -f $(MOFILES)
	@rm -f $(POFILES:.po=.po~)

showtrans:
	@sed -n '/^\([^#].*\)\?gettext/ { s/gettextvar \+[^ ]\+ /gettext /g; p }' $(SRCFILES)
updatepot:
	@[ -e $(POTFILE) ] || touch $(POTFILE)
	@sed -n '/^\([^#].*\)\?gettext/ { s/gettextvar \+[^ ]\+ /gettext /g; p }' $(SRCFILES) | xgettext \
		--from-code=utf-8 \
		-L Shell \
		--no-location \
		--no-wrap \
		--omit-header \
		-d $(PACKAGE) \
		-j \
		-o $(POTFILE) \
		-
	@for i in $(POFILES); do \
		echo -n "merging $$i "; \
		msgmerge -NU $$i $(POTFILE); \
	done

.PHONY: help all build clean createpot updatepot
