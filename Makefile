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

SHELL=/bin/bash

.PHONY: apply-version update-tag push-tag check-kit create-kit erase-kit build clean pre-publish publish-common git-pull git-push git-status release-draft release-draft-upload release-list

# Given:
#   - Kit has files to be packaged
#   - Kit has a make-kit.mk file in {root} of its repo
# When:
#   - make-kit.mk defines any of 'kit_depends'...
# Then:
#   - Makefile will use the values set in make-kit.mk

none:
	@if [ ! -d ./shellkit ]; then \
		echo "You're in the wrong directory.  This Makefile is intended for use in the parent of ./shellkit";  \
		exit 1 ;\
	fi
	@echo There is no default target. Try create-kit to start from scratch.

version := $(shell cat ./version)
kitname := $(shell cat bin/Kitname)
setup_script := $(kitname)-setup-$(version).sh
Ghx := gh
ShellkitWorkspace:=$(shell for dir in .. ../.. ../../.. ../../../..; do  [[ -f $${dir}/.shellkit-workspace ]] && { ( cd $${dir}; pwd ); break; }; done )

-include ./make-kit.mk  # Project-specific makefile

ConformityDockerComponent=shellkit-conformity
ComponentDockerMakefile=$(ShellkitWorkspace)/.devcontainer/shellkit-component.mk

build_depends += $(shell find bin/* -type f)
build_depends += shellkit/Makefile shellkit/makeself.sh make-kit.mk shellkit/makeself-header.sh
build_depends += shellkit/realpath.sh shellkit/setup-base.sh shellkit/shellkit-help.sh
build_depends += shellkit/loader/shellkit-loader.bashrc shellkit/loader/shellkit-loader.sh

git_remote := $(shell command git status -sb| command sed -e 's/\.\.\./ /' -e 's%/% %g' | command awk {'print $$3'})
git_shellkit_remote := $(shell cd shellkit && git remote -v | grep -E '\(push\)' | awk '{print $$1}')

next_steps_doc:=https://github.com/sanekits/shellkit/blob/main/docs/create-kit-next-steps.md

clean:
	rm -rf tmp

.PHONY: print-build-depends
print-build-depends:
	@echo build_depends=$(build_depends)


.PHONY: shellkit-ref-validate
shellkit-ref-validate:
	@# If there's no shellkit-ref file, then the embedded shellkit branch should be 'main'
	@# If there IS a shellkit-ref file, then the embedded shellkit branch should match
	@die() { echo "ERROR: $$*" >&2; exit 1; }; \
	shkbranch="$$( cd shellkit &>/dev/null && git rev-parse --abbrev-ref HEAD )" ; \
		decbranch=$$(cat ./shellkit-ref 2>/dev/null); \
		[[ -n $$decbranch ]] && { [[ $$decbranch == $$shkbranch ]] && exit 0 || die "current shellkit branch [$$shkbranch] does not match ./shellkit-ref [$$decbranch]"; }; \
		[[ $$shkbranch == main ]] || die "current shellkit branch should be 'main' because there's no ./shellkit-ref";

tree-setup: shellkit-ref-validate

build: tree-setup tmp/$(setup_script) build-hash


tmp/$(setup_script) tmp/latest.sh build-hash: $(build_depends)
	mkdir -p ./tmp && \
    shellkit/makeself.sh --follow --base64 ./bin tmp/$(setup_script) "${kitname} ${version} setup" ./setup.sh
	ln -sf $(setup_script) tmp/latest.sh
	/bin/bash -x tmp/latest.sh --list 2>&1 | grep -E '\+ MD5=' | sed 's/+ MD5=//' > build-hash
	-git add build-hash && git commit build-hash -m "build-hash updated"
	@echo "Done: ${kitname}:${version} $$(cat build-hash)"


create-kit: shellkit/.git
	./shellkit/create-kit.sh
	NONTFATAL_HASH_MISMATCH=1 ./shellkit/check-kit.sh
	@echo "Kit created OK.  See ${next_steps_doc} for next steps."


check-shellkit:
	xdir=./shellkit/loader/test; make -C $$xdir -f taskrc.mk test

check-kit: check-shellkit
	./shellkit/check-kit.sh


.PHONY: conformity-check
conformity-check: $(ComponentDockerMakefile)
    # See shellkit/docs/conformity-testing.md
	make -f $(ComponentDockerMakefile) Component=$(ConformityDockerComponent) image

    # You can add KeepShell=1 to avoid closing the container after conformity checks
    #
    #  Below we map the ~/.local/bin dir to a host-side /tmp/fakelocalbin-latest symlink
    #  that points to a temp dir.  This allows the dev to easily follow the changes
    #  in the container made to the install root.
    #
    #  If KeepShell=1, the temp dir is not destroyed on container exit.
    #
	[[ -n "${KeepShell}" ]] && stay="--keep-shell"; \
	tmpLocalBin=$$( mktemp -d -p /tmp fakelocalbin-XXXXX ); \
		mkdir -p $$tmpLocalBin; \
		chown $$(id -u):$$(id -u) $$tmpLocalBin; \
		chmod oug+rx $$tmpLocalBin; \
		rm $$(dirname $$tmpLocalBin)/fakelocalbin-latest; \
		ln -sf $$tmpLocalBin $$(dirname $$tmpLocalBin)/fakelocalbin-latest; \
		echo "Host tmpLocalBin=$$tmpLocalBin"; \
	make -f $(ComponentDockerMakefile) \
		Volumes="-v $(ShellkitWorkspace)/$(kitname):/workspace:ro -v $$tmpLocalBin:/home/vscode/.local/bin -v $(ShellkitWorkspace):/shellkit-workspace" \
		Component=$(ConformityDockerComponent) \
		Command="bash -i shellkit/conformity/conformity-check.sh --kit $(kitname) $$stay" \
		run; \
	[[ -z "${KeepShell}" ]] && [[ -d $$tmpLocalBin ]] && rm -rf $$tmpLocalBin || :

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
	git push ${git_remote} tag ${version} -f
	cd shellkit && git push ${git_shellkit_remote} tag ${kitname}-${version} -f

apply-version: version $(version_depends)
	# Apply the updated ./version to files which have
	# version dependencies
	shellkit/apply-version.sh ${apply_version_extra_files}

pre-publish: apply-version build git-status-clean update-tag check-kit tmp/$(setup_script)
	@echo pre-publish completed OK

publish-common: git-pull pre-publish ${publish_extra_files}
	@# Common logic needed to publish a kit
	@echo Copying extra files: ${publish_extra_files}
	@bash -c '[[ -n "${publish_extra_files}" ]] \
		&& { \
			cp ${publish_extra_files} ${HOME}/tmp/; \
		} || { :; } '

git-pull:
	cd shellkit && command git pull && git status
	command git pull && git status

git-push:
	cd shellkit && command git push && git status
	command git push && git status

git-status:
	cd shellkit && git status
	git status

release-draft: build git-push push-tag
	rm tmp/draft-url || :
	$(Ghx) release delete --yes ${version} || :
	$(Ghx) release create ${version} --notes "Version ${version}" --draft --title ${version} > tmp/draft-url
	# Wait until the release shows up on view...
	while ! $(Ghx) release view ${version}; do \
		sleep 4  # Takes time for the release to be processed! \
	done
	cat tmp/draft-url

release-draft-upload: release-draft
	$(Ghx) release view ${version}
	@echo publish_extra_files=${publish_extra_files}
	$(Ghx) release delete-asset --yes ${version} $(setup_script) ${publish_extra_files} || :
	$(Ghx) release upload ${version} tmp/$(setup_script) ${publish_extra_files}
	cat tmp/draft-url

release-list:
	$(Ghx) release list | sort -n | tail -n 8
	$(Ghx) release view ${version}

