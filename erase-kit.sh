#!/bin/bash
# erase-kit.sh

scriptName="$(command readlink -f $0)"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR(${scriptName}): $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}
main() {
    [[ -d ./shellkit ]] || die main.1.1 No ./shellkit here
    local tmpdir="$(mktemp -d)"
    local killDir=${PWD}
    builtin cd ${tmpdir} || die main.2
    command rsync -av "${killDir}" . || die main.3
    local killList=(  \
        $( \
            builtin cd ${killDir} || die; \
            ls -a | grep -Ev '(^shellkit$)|(^Makefile$)|(^\.$)|(^\.\.$)';
        ) \
        )
    echo "This script is very, very destructive!"
    echo "It will delete all files in ${killDir} except:"
    echo "    - shellkit/"
    echo "    - ./Makefile -> shellkit/Makefile"
    echo "Here's what you will lose:"
    echo "${killList[@]}" | command sed 's/^/   /'
    read -p "If you're really sure, type \"yes\":"
    [[ $REPLY == yes ]] || die main.2 Probably smart to quit
    [[ -n "${killList[@]}" ]] || die main.4
    (
        builtin cd $killDir || die main.4.1
        command rm -rf "${killList[@]}" || die main.4.2
    ) || die main.7

    echo "Done: Backup saved to ${tmpdir}"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
