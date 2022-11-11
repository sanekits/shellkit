#!/bin/bash
# make-conformity-image.sh
# see docs/conformity-testing.md

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")
PS4='\033[0;33m+(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

stub() {
    # Print debug output to stderr.  Recommend to call like this:
    #   stub "${FUNCNAME[0]}.${LINENO}" "$@" "<Put your message here>"
    #
    [[ -n $NoStubs ]] && return
    [[ -n $__stub_counter ]] && (( __stub_counter++  )) || __stub_counter=1
    {
        builtin printf "  <=< STUB(%d:%s)" $__stub_counter "$(basename $scriptName)"
        builtin printf "[%s] " "$@"
        builtin printf " >=> \n"
    } >&2
}

main() {
    local image_name
    while [[ -n $1 ]]; do
        case "$1" in
            --version) Version=$2; shift;;
            --image) image_name=$2; shift;;
            *) die "Expected --version n.n.n";;
        esac
        shift
    done
    [[ $Version =~ [0-9]+\.[0-9]+\.[0-9]+$ ]] || die "--version must match nn.nn.nn, not [$Version]"
    [[ -n $image_name ]] || die "--image undefined"

    cd shellkit/conformity &&
        docker build . -t "$image_name" ||
           die "Failed building $image_name"

        echo "Docker image $image_name built: OK"
    true
}

[[ -z ${sourceMe} ]] && {
    stub "${FUNCNAME[0]}.${LINENO}" "$@" "calling main()"
    main "$@"
    builtin exit
}
command true
