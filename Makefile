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

build_depends := bin/Kitname shellkit/Makefile $(kit_depends)

none:
	@echo There is no default target.

build: $(build_depends)
	publish/publish-via-github-release.sh

create-kit: shellkit/.git
	./shellkit/create-kit.sh

erase-kit:
	shellkit/erase-kit.sh

apply-version:
	shellkit/apply-version.sh
