#!/bin/bash
# erase-kit.sh

scriptName="$(command readlink -f "$0")"

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}
main() {
    [[ -d ./shellkit ]] || die main.1.1 No ./shellkit here
    local tmpdir;tmpdir="$(mktemp -d)"
    local killDir=${PWD}
    builtin cd "${tmpdir}" || die main.2
    command rsync -av "${killDir}" . || die main.3
    local killList
    mapfile -t killList < <(  builtin cd "${killDir}" || die; command ls -a | grep -Ev '(^shellkit$)|(^Makefile$)|(^\.$)|(^\.\.$)' )
    echo "This script is very, very destructive!"
    echo "It will delete all files in ${killDir} except:"
    echo "    - shellkit/"
    echo "    - ./Makefile -> shellkit/Makefile"
    echo "Here's what you will lose:"
    echo "${killList[@]}" | command sed 's/^/   /'
    [[ -n "${killList[*]}" ]] || {
        echo "WARNING: No files here to kill." >&2
        exit
    }
    if [[ -z $FORCE_ERASE ]]; then
        echo "We made a backup in ${tmpdir}, but you know how things go..."
        echo "(Note: define FORCE_ERASE=1 to bypass confirmation prompt)"
        read -rp "If you're really sure, type \"yes\"."
        [[ $REPLY == yes ]] || die main.2 Probably smart to quit
    else
        echo "YOU \$FORCE_ERASE this!" >&2
    fi
    (
        builtin cd "$killDir" || die main.4.1
        command rm -rf "${killList[@]}" || die main.4.2
    ) || die main.7

    echo "Done: See ${tmpdir} for backup contents."
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
