#!/bin/bash
# <Kitname>.sh
#  This script can be removed if you don't need it -- and if you do
# that you should remove the entry from _symlinks_ and make-kit.mk also.

canonpath() {
    type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    type -t readlink &>/dev/null && {
        readlink -f "$@"
        return
    }
    # Fallback: Ok for rough work only, does not handle some corner cases:
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}

scriptName="$(canonpath "$0")"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}
main() {
    builtin echo "Hello <Kitname>, shellkit edition: args:[$*]"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
