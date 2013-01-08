PACKAGE = generate
POFILES = $(wildcard po/*.po)
MOFILES = $(POFILES:.po=.mo)
POTFILE = po/$(PACKAGE).pot
DISTRONAME = SalixLive

help:
	@echo "Help:"
	@echo "  build        build the .mo files"
	@echo "  all          build"
	@echo "  clean        remove all .mo and .po~ files"
	@echo "  updatetrans  update ${POTFILE} from ${PACKAGE} and generate/update .po files"

all: build

build: $(MOFILES)

%.mo : %.po
	@echo "Compiling $<"
	$(shell sh ./pohelper "$(DISTRONAME)" $<)

clean:
	@rm -f $(MOFILES)
	@rm -f $(POFILES:.po=.po~)

updatetrans:
	@touch $(POTFILE)
	xgettext --from-code=utf-8 \
		-j \
		-L Python \
		--add-comments=\# \
		-o $(POTFILE) \
		$(PACKAGE)
	@for i in $(POFILES); do \
		msgmerge -NU $$i $(POTFILE); \
	done

.PHONY: help all build clean updatetrans
