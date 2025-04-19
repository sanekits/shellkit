#!/bin/bash
# start-lab.sh: create a docker-lab container and 
# call the kit's .docker-lab-postcreate hook to customize it

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")
#shellcheck disable=2154
PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}


main() {
    set -ue
    [[ -x "${scriptDir}/entrypoint.sh" ]] || die 101
    chmod 755 "${scriptDir}/entrypoint.sh" || die 101.5
    [[ -d "$PWD/../docker-test" ]] || die 102
    export SHK_WORKAREA="$PWD"
    cd "$PWD/../docker-test" || die 103
    labData=/bb/spaces/shared/shk-docker-lab-data
    [[ -d "${labData}" ]] || {
        mkdir "${labData}"
        chown 1000:1000 "${labData}"
    }
    docker compose run --rm docker-lab "$@"
}

if [[ -z "${sourceMe}" ]]; then
    main "$@"
    builtin exit
fi
command true
