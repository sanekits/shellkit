#!/bin/bash
# git-status-clean.sh

canonpath() {
    builtin type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    builtin type -t readlink &>/dev/null && {
        command readlink -f "$@"
        return
    }
    # Fallback: Ok for rough work only, does not handle some corner cases:
    ( builtin cd -L -- "$(command dirname -- "$0")" || return; builtin echo "$(command pwd -P)/$(command basename -- "$0")" )
}


scriptName="$(canonpath "$0")"

die() {
    builtin echo "ERROR($(basename "${scriptName}"): $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

dirtyFiles() {
    (
        builtin cd "$1" || die dirtyFiles.1
        if [[ $( command git status -s . | command wc -l 2>/dev/null) -gt 0 ]]; then
            echo "WARNING: Uncommited files found in $PWD" >&2
            exit
        fi
        false
    )
}

[[ -z ${sourceMe} ]] && {
    [[ -f ./version ]] || die "No version file in $PWD"
    [[ -d .git ]] || die "Not a git working tree: $PWD"
    [[ -d ./shellkit ]] || die "No ./shellkit/ child dir in $PWD"
    dirty=false
    for xdir in $PWD $PWD/shellkit; do
        dirtyFiles "${xdir}" && dirty=true
    done
    $dirty && exit 1
}
command true
