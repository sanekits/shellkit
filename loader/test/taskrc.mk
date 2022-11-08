# taskrc.mk for test
#


absdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
REMAKE := $(MAKE) -C $(absdir) -s -f $(lastword $(MAKEFILE_LIST))

.PHONY: help
help:
	@echo "Targets in $(basename $(lastword $(MAKEFILE_LIST))):" >&2
	@$(REMAKE) --print-data-base --question no-such-target 2>/dev/null | \
	grep -Ev  -e '^taskrc.mk' -e '^help' -e '^(Makefile|GNUmakefile|makefile|no-such-target)' | \
	awk '/^[^.%][-A-Za-z0-9_]*:/ \
			{ print substr($$1, 1, length($$1)-1) }' | \
	sort | \
	pr --omit-pagination --width=100 --columns=3
	@echo -e "absdir=\t\t$(absdir)"
	@echo -e "CURDIR=\t\t$(CURDIR)"
	@echo -e "taskrc_dir=\t$${taskrc_dir}"

tmp:
	mkdir tmp

.PHONY: loadsort-set1
loadsort-set1: tmp
	# set1 should have no errors:
	SHLOADER_DIR=./set1 ../shellkit-loader.sh 2> tmp/set1.err > tmp/set1.out
	diff tmp/set1.out set1/out.ref
	diff tmp/set1.err set1/err.ref

.PHONY: loadsort-set2
loadsort-set2: tmp
	# set2 has a cycle from kit3 -> kit5 -> kit3
	SHLOADER_DIR=./set2 ../shellkit-loader.sh 2> tmp/set2.err > tmp/set2.out
	diff tmp/set2.out set2/out.ref
	diff tmp/set2.err set2/err.ref

.PHONY: loadsort-set3
loadsort-set3: tmp
	# set3 has a cycle from kit3 -> kit5 -> kit3
	SHLOADER_DIR=./set3 ../shellkit-loader.sh 2> tmp/set3.err > tmp/set3.out
	diff tmp/set3.out set3/out.ref
	diff tmp/set3.err set3/err.ref

..PHONY: test
test: loadsort-set1 loadsort-set2
	echo All tests pass


