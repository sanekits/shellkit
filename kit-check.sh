#!/bin/bash
# kit-check.sh:  integrity check for a shellkit-based  tool.  Checks for compatibility and common errors pre-publish

scriptName="$(command readlink -f $0)"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

checkLocalTag() {
    # Given:
    #   - git working copy root is $PWD
    # When:
    #   - a git tag exists that matches the contents of ./version
    #   - the HEAD revision in git matches the tag revision
    #   - There are no dirty files
    # Then:
    #   - Function returns 0 and prints nothing
    # Otherwise:
    #   - Function returns nonzero and prints warning
    local _version=$(cat ./version)
    [[ -z $_version ]] && die "No version detected in checkLocalTag"

    local version="${_version//./\~}"
    command git tag | command sed 's/\./~/g' | command grep -Eq "${version}" || {
        return $(die "No git tag with version $_version")
    }
    local head_hash=$( command git rev-parse HEAD )
    [[ -n $head_hash ]] || return $(die "Can't find git HEAD hash")
    local tag_hash=$( command git rev-parse ${_version} )
    [[ -n $tag_hash ]] || return $(die "Can't find git has for tag $_version")
    [[ "$head_hash" == "$tag_hash" ]] || {
        return $(die "HEAD hash does not match tag $_version")
    }

    if [[ $( command git status -s . | command wc -l 2>/dev/null) -gt 0 ]]; then
        return $(die "Uncommited files found: commit them and then update version and tag or force-update tag")
    fi
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

    checkLocalTag  || die 103.4
    echo "All checks passed OK"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
