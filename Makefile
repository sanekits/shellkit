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

.PHONY: publish apply-version update-tag push-tag check-kit create-kit erase-kit build clean pre-publish

# Given:
#   - Kit has files to be packaged
#   - Kit has a make-kit.mk file in {root} of its repo
# When:
#   - make-kit.mk defines any of 'kit_depends'...
# Then:
#   - Makefile will use the values set in make-kit.mk

-include ./make-kit.mk  # Project-specific makefile

build_depends += $(wildcard bin/*) $(wildcard bin/shellkit/*) shellkit/Makefile shellkit/makeself.sh make-kit.mk shellkit/makeself-header.sh shellkit/realpath.sh shellkit/setup-base.sh shellkit/shellkit-help.sh

version := $(shell cat ./version)
kitname := $(shell cat bin/Kitname)
setup_script := $(kitname)-setup-$(version).sh

next_steps_doc:=https://github.com/sanekits/shellkit/blob/main/docs/create-kit-next-steps.md

none:
	@if [ ! -d ./shellkit ]; then \
		echo "You're in the wrong directory.  This Makefile is intended for use in the parent of ./shellkit";  \
		exit 1 ;\
	fi
	@echo There is no default target. Try create-kit to start from scratch.

build: tmp/latest.sh tmp/${setup_script} build-hash

clean:
	rm -rf tmp/*

tmp/${setup_script} tmp/latest.sh build-hash: $(build_depends)
	mkdir -p ./tmp && \
    shellkit/makeself.sh --follow --base64 ./bin tmp/${setup_script} "${kitname} ${version} setup" ./setup.sh
	ln -sf ${setup_script} tmp/latest.sh
	/bin/bash -x tmp/latest.sh --list 2>&1 | grep -E '\+ MD5=' | sed 's/+ MD5=//' > build-hash
	-git add build-hash && git commit build-hash -m "build-hash updated"
	@echo "Done: ${kitname}:${version} $$(cat build-hash)"


create-kit: shellkit/.git
	./shellkit/create-kit.sh
	NONTFATAL_HASH_MISMATCH=1 ./shellkit/check-kit.sh
	@echo "Kit created OK.  See ${next_steps_doc} for next steps."

check-kit:
	./shellkit/check-kit.sh

erase-kit:
	# Destroy everything but the scaffolding.
	shellkit/erase-kit.sh

install-kit:
	# Install kit in current shell
	tmp/latest.sh

update-tag:
	git tag ${version} -f
	cd shellkit && git tag ${kitname}-${version} -f

git-status-clean:
	shellkit/git-status-clean.sh

push-tag:
	git push --tag -f
	cd shellkit && git push --tag -f

apply-version: version $(version_depends)
	# Apply the updated ./version to files which have
	# version dependencies
	shellkit/apply-version.sh

pre-publish: apply-version build git-status-clean update-tag check-kit push-tag
	@echo pre-publish completed OK

publish-common: pre-publish ${HOME}/downloads
	# Common logic needed to publish a kit
	cp ${setup_script} ${HOME}/downloads
	@echo "Script ${HOME}/downloads/${setup_script} should be attached to the release artifacts"

