PACKAGE = salt
SRCFILES = $(wildcard ../build/boot/grub/*.cfg)
POFILES = $(wildcard po/*.po)
MOFILES = $(POFILES:.po=.mo)
POTFILE = po/$(PACKAGE).pot
DISTRONAME = SalixLive

help:
	@echo "Help:"
	@echo "  build        build the .mo files"
	@echo "  clean        remove all .mo and .po~ files"
	@echo "  updatepot    update ${POTFILE} from *.cfg and generate/update po/*.po files"
	@echo "  all          updatepot + build"

all: updatepot build

build: $(MOFILES)

%.mo : %.po
	@echo "Compiling $<"
	$(shell sh ./pohelper "$(DISTRONAME)" $<)

clean:
	@rm -f $(MOFILES)
	@rm -f $(POFILES:.po=.po~)

updatepot:
	@[ -e $(POTFILE) ] || touch $(POTFILE)
	@sed -n '/^\([^#].*\)\?gettext\(var\)\? / { s/.*gettext\(var \+[^ ]\+\)\? \+\("[^"]\+"\)/eval_gettext \2/; p }' $(SRCFILES) | xgettext \
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
		msgmerge -NU $$i $(POTFILE); \
	done

.PHONY: help all build clean createpot updatepot
