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
.ONESHELL:
.SUFFIXES:
.SHELLFLAGS = -uec
MAKEFLAGS += --no-builtin-rules --no-print-directory


# Beware: absdir points to <kitname>/shellkit NOT <kitname>!
absdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST) )))
# kitdir does not contain the troublesome trailing / !
kitdir := $(realpath $(absdir)..)

Flag := $(kitdir)/tmp/flag
Finit := $(Flag)/.init

#	PS4=$(PS4x)  # <-- Copy/uncomment this in recipe to enable smart PS4 
PS4x='$$( _0=$$?;_1="$(notdir $@)";_2="$(realpath $(lastword $(MAKEFILE_LIST)))"; exec 2>/dev/null; echo "$${_2}|$${_1}@+$${LINENO} ^$$_0 $${FUNCNAME[0]:-?}()=>" ) '

foo:
	echo This is $@

.PHONY: apply-version verbump update-tag push-tag check-kit create-kit erase-kit build clean pre-publish publish-common git-pull git-push git-status release-draft-upload release-list release-core release-core-upload release-upload


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
Ghx := GH_TOKEN=$$GH_TOKEN_2 command gh
ShellkitWorkspace:=$(shell for dir in .. ../.. ../../.. ../../../..; do  [[ -f "$${dir}/.shellkit-workspace" ]] && { ( cd "$${dir}"; pwd ); break; }; done )
DockertestDir := $(realpath $(kitdir)/../docker-test/bin)
DockertestRun := SHK_WORKAREA=$(kitdir) $(DockertestDir)/docker-test.sh

-include ./make-kit.mk  # Project-specific makefile


# If the bin/shellkit/{symlinks} are not present, we want to induce a hard failure during 'make build'.
# This adapts to a historical oversight, in which some kits were missing the symlinks.
# You can retrofit an old kit by running the '.fix-shellkit-symlinks' target.
build_depends += $(shell find bin/* -type f; echo bin/shellkit/{realpath,setup-base,shellkit-loader}.sh bin/shellkit/shellkit-loader.bashrc | sort -u)
build_depends += shellkit/Makefile shellkit/makeself.sh make-kit.mk shellkit/makeself-header.sh
build_depends += shellkit/realpath.sh shellkit/setup-base.sh shellkit/shellkit-help.sh
build_depends += shellkit/loader/shellkit-loader.bashrc shellkit/loader/shellkit-loader.sh


git_remote := $(shell command git status -sb| command sed -e 's/\.\.\./ /' -e 's%/% %g' | command awk '{print $$3}')
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
	PS4=$(PS4x)
	die() {
		echo "ERROR: $$*" >&2
		exit 1
	}
	shkbranch="$$( cd shellkit &>/dev/null && git rev-parse --abbrev-ref HEAD )"
	decbranch=$$(cat ./shellkit-ref 2>/dev/null || echo )
	[[ -n $$decbranch ]] \
		&& {
			[[ $$decbranch == $$shkbranch ]] \
				&& exit 0 \
				|| die "current shellkit branch [$$shkbranch] does not match ./shellkit-ref [$$decbranch]"
	};
	[[ $$shkbranch == main ]] \
		|| die "current shellkit branch should be 'main' because there's no ./shellkit-ref";

tree-setup: $(Finit) shellkit-ref-validate

ifdef NoDefaultBuild
# If NoDefaultBuild is defined, this  build target will not be available
else
build: tree-setup tmp/$(setup_script) build-hash
endif

verbump:
	./shellkit/version-bump.sh ./version

tmp/$(setup_script) tmp/latest.sh build-hash: $(build_depends)
	@
	PS4=$(PS4x)
	mkdir -p ./tmp && \
		shellkit/makeself.sh --follow --base64 ./bin tmp/$(setup_script) "${kitname} ${version} setup" ./setup.sh
	ln -sf $(setup_script) tmp/latest.sh
	/bin/bash -x tmp/latest.sh --list 2>&1 | grep -E '\+ MD5=' | sed 's/+ MD5=//' > build-hash
	git add build-hash
	git commit build-hash -m "build-hash updated" ||  :
	echo "Done: ${kitname}:${version} $$(cat build-hash)"


create-kit: shellkit/.git
	./shellkit/create-kit.sh
	NONTFATAL_HASH_MISMATCH=1 ./shellkit/check-kit.sh
	@echo "Kit created OK.  See ${next_steps_doc} for next steps."


check-shellkit:
	xdir=./shellkit/loader/test; make -C $$xdir -f taskrc.mk test

check-kit: check-shellkit
	./shellkit/check-kit.sh || :

$(Flag)/reconcile-kit reconcile-kit:  $(Finit)
	@# Present template-based kit files for manual diff/reconciliation with template
	PS4=$(PS4x)	
	#set -x
	errs=()
	set +u
	while read -r tmplfile kitfile ; do
		[[ -n $$tmplfile ]] || { errs+=("WARNING: Can't find one or both of $$kitfile $$tmpfile"); continue; }
		$(shell shellkit/which-code.sh) --diff $$tmplfile $$kitfile -w
	done < <( printf "%s %s\n" "shellkit/templates/make-kit.mk.template ./make-kit.mk
		shellkit/templates/bin/setup.sh bin/setup.sh
		shellkit/templates/bin/kitname-version.sh bin/$(kitname)-version.sh
		shellkit/templates/bin/kitname.sh bin/$(kitname).sh "
	)
	if [[ $${#errs} -gt 0 ]]; then
		printf "Errors:  " ; printf "%s\n" "${errs[@]}"
		exit 1
	fi
	read -p "Hit Enter to mark reconciliation flag or Ctrl+C to abort"
	touch $(Flag)/reconcile-kit


KeepShell = 0   # 0=no, 1=pause before test, 2=pause after test
.PHONY: conformity-check
conformity-check:
	@ set +ue
    #  Options:
    # - KeepShell=1  -- sleep before running conformity check.  
    # - KeepShell=2  -- sleep after running conformity check.
	KeepShell=$(KeepShell) $(DockertestRun) conformity-check



erase-kit:
	# Destroy everything but the scaffolding.
	shellkit/erase-kit.sh

install-kit:
	# Install kit in current shell
	tmp/latest.sh

update-tag:
	@
	PS4=$(PS4x)
	git tag $(version) -f
	cd shellkit && git tag $(kitname)-$(version) -f

git-status-clean:
	shellkit/git-status-clean.sh || :

push-tag:
	@
	PS4=$(PS4x)
	git push $(git_remote) tag $(version) -f
	cd shellkit && git push $(git_shellkit_remote) tag $(kitname)-$(version) -f

apply-version: version $(version_depends)
	# Apply the updated ./version to files which have
	# version dependencies
	shellkit/apply-version.sh ${apply_version_extra_files}

pre-publish: apply-version build git-status-clean update-tag check-kit tmp/$(setup_script)
	@echo pre-publish completed OK

publish-common: git-pull pre-publish ${publish_extra_files}
	@
	# Common logic needed to publish a kit
	export PS4x=$(PS4x)
	echo Copying extra files: ${publish_extra_files}
	cat <<-EOF | bash -s -
	PS4=$(PS4x)
	if [[ -n "${publish_extra_files}" ]]; then 
		cp ${publish_extra_files} ${HOME}/tmp/ 
	else 
		: 
	fi
	EOF

git-pull:
	@
	PS4=$(PS4x)
	cd shellkit && command git pull --no-tags && git status
	command git pull --no-tags && git status

git-push:
	cd shellkit && command git push && git status
	command git push && git status

git-status:
	cd shellkit && git status
	git status

release-core: build git-push push-tag
	rm tmp/draft-url || :
	$(Ghx) release delete --yes ${version} || :
	$(Ghx) release create ${version} --notes "Version ${version}" $(DraftOption) --title ${version} > tmp/draft-url
	# Wait until the release shows up on view...
	while ! $(Ghx) release view ${version}; do \
		sleep 4  # Takes time for the release to be processed! \
	done
	cat tmp/draft-url

release-core-upload: release-core
	$(Ghx) release view ${version}
	@echo publish_extra_files=${publish_extra_files}
	$(Ghx) release delete-asset --yes ${version} $(setup_script) ${publish_extra_files} || :
	$(Ghx) release upload ${version} tmp/$(setup_script) ${publish_extra_files}
	cat tmp/draft-url

release-draft-upload:
	$(MAKE) DraftOption=--draft release-core-upload
	echo "OK: relase published DRAFT"

release-upload: release-core-upload
	echo "OK: release published final (not draft)"

release-list:
	$(Ghx) release list | sort -n | tail -n 8
	$(Ghx) release view ${version}

.fix-shellkit-symlinks:
	@
	cd bin
	mkdir -p shellkit
	cd shellkit
	ln -sf ../../shellkit/{realpath,setup-base,loader/shellkit-loader}.sh ../../shellkit/loader/shellkit-loader.bashrc  ./

..PHONY: docker-lab
docker-lab:
	@
	# Creates a containerized testing environment.  Kits can define prereqs for the .docker-lab-postcreate to 
	# customize the state of the container after creation.  
	#    - The hooks will run inside the container after creation (during entrypoint)
	# 	 - The /workarea of the container is the root of the kit source tree
	#    - /bb-shellkit is a readonly mount of the environment root
	#    - /share is a docker volume mounted read/write
	#    - /host_home exposes selected subdirs as readonly
	#
	#   Example post-create hook (in make-kit.mk):
	#      .docker-lab-postcreate: .my-hook
	#      .my-hook:
	#          # Do something to prepare the container here
	@
	$(DockertestRun)  docker-lab

docker-testlab:
	@  # Same as docker-lab target, except we do not trigger the .docker-lab-postcreate target.
	   # (which makes it easier to debug that sort of thing or not have it interfere with exploration)
	echo "Launching docker-testlab.  This will not invoke .docker-lab-postcreate."
	echo "Use jumpstart_ep to init environment."
	$(DockertestRun) --no-postcreate docker-lab

.docker-lab-postcreate:
	@ # This is just a dependency hook: add depends to this which will run during docker-lab entrypoint

$(Finit) .finit:
	mkdir -p $(Flag)
	touch $(Finit)

Makefile: ;
