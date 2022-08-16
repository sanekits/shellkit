# shellkit Makefile
#
#  Setting up a shellkit-based tool:
#
#  1. Create a directory.  Choose name carefully,
#    as this will become the name of the kit.  No spaces. Must
#    be unique among all kits in ~/.config/shellkit-meta/packages
#    Use [a-zA-Z][:alnum:]-_ to restrict name charset
#  2. cd into new dir
#  3. git clone git@github.com:sanekits/shellkit
#  4. ln -sf shellkit/Makefile
#  5. make create-kit
#
#  Using a kit-local Makefile
#    - Must be named {root}/make-kit.mk

.PHONY: publish create-kit erase-kit

# Given:
#   - Kit has files to be packaged
#   - Kit has a make-kit.mk file in {root} of its repo
# When:
#   - make-kit.mk defines any of 'kit_depends'...
# Then:
#   - Makefile will use the values set in make-kit.mk

-include ./make-kit.mk  # Project-specific makefile

build_depends += bin/Kitname shellkit/Makefile
version := $(shell cat ./version)
version_depends += README.md

none:
	@echo There is no default target. Try create-kit to start from scratch.

build: $(build_depends)
	mkdir -p ./tmp && \
    shellkit/makeself.sh --follow --base64 ./bin tmp/latest.sh "kitname version" ./setup.sh

create-kit: shellkit/.git
	./shellkit/create-kit.sh
	./shellkit/kit-check.sh
	echo "Kit created OK"

kit-check:
	./shellkit/kit-check.sh

erase-kit:
	# Destroy everything but the scaffolding.
	shellkit/erase-kit.sh

apply-version: version $(version_depends)
	# Apply the updated ./version to files which have
	# version dependencies
	shellkit/apply-version.sh
