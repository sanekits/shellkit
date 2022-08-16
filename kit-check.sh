#!/bin/bash
# kit-check.sh:  integrity check for a shellkit-based  tool.  Checks for compatibility and common errors pre-publish

scriptName="$(command readlink -f $0)"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

checkTag() {
    # verify existence of local tag matching version
    local version=$1
    [[ -z $version ]] && die "No version passed to checkTag"

    version="${version//./\~}"
    command git tag | command sed 's/\./~/g' | command grep -Eq "${version}" || {
        builtin echo "No git tag with version $1" >&2
        false
        return
    }
    true
}

main() {
    [[ -L Makefile ]] || die "No ./Makefile symlink"
    [[ -f bin/Kitname ]] || die "bin/Kitname" is missing in $PWD
    [[ -f shellkit/makeself.sh ]] || die "shellkit/makeself.sh is missing"
    local Kitname=$(basename $PWD)
    grep -Eq "^${Kitname}\$" bin/Kitname || die "bin/Kitname does not contain \"${Kitname}\""
    grep -Eq "^${Kitname} " ~/.config/shellkit-meta/packages || echo "WARNING: ${Kitname} not listed in ~/.config/shellkit-meta/packages.  Add it to master shellkit-meta package list"
    [[ -x bin/setup.sh ]] || die "bin/setup.sh" is missing
    [[ -d bin/shellkit ]] || die "bin/shellkit dir is missing"

    command git ls-files | grep -Eq '^shellkit/' && die "At least one ./shellkit path is in git but should be ignored"
    [[ -L bin/shellkit/setup-base.sh ]] || die "bin/shellkit/setup-base.sh symlink is missing"
    local version=$( bin/${Kitname}-version.sh | cut -f2)
    [[ -z $version ]] && die "Bad version number from bin/${Kitname}-version.sh"

    [[ -z $rawPublish ]] && {
            if [[ $( command git status -s | command wc -l 2>/dev/null) -gt 0 ]]; then
            echo "WARNING: one or more files in $PWD need to be committed before publish"
        fi
    }
    checkTag  ${version} || die 103.4
    echo "All checks passed OK"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
