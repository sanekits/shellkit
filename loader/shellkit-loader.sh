#!/bin/bash
# shellkit-loader.sh
#
# Invoked by shellkit-loader.bashrc during shell startup, this
# script scans the installed shellkits and sorts their
# dependencies, producing a load ordering.
#
# It prints the load ordering as a list of init scripts to
# be sourced.
#
# If a cycle or missing dependency is detected, it prints to
# stderr, but continues with a best-effort to yield the
# load order list anyway.

scriptName="$(readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

PS4='\033[0;33m+(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'



die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

SHELLKIT_LOAD_DISABLE=1 source ${scriptDir}/shellkit-loader.bashrc
[[ -n $SHELLKIT_LOADER_VER ]] || die "Missing ${scriptDir}/shellkit-loader.bashrc or SHELLKIT_LOADER_VER not defined"

stub() {
    {
        builtin printf "  <<< STUB "
        builtin printf "[%s] " "$@"
        builtin printf ">>>\n"
    } >&2
}

get_kit_depends() {
    # List unordered kit dependency tuples like:
    #     kit1 kit3
    #     kit3 kit4
    #     kit3 -
    # When the dependency is '-', it's just filler to ensure
    # all dependents are included in the output.
    local kitnames=()
    kitnames+=( $(command ls */Kitname 2>/dev/null | command xargs dirname 2>/dev/null) )

    for kit in ${kitnames[@]}; do
        printf "${kit} -\n"
        [[ -f ${kit}/load-depends ]] && {
            # We want one or more lines like [kitname] [dependency]
            # as input for tsort:
            grep -Ev ' *#' ${kit}/load-depends | sed "s/^/${kit} /"
        }
    done
}

format_tsort_errs() {
    local first=true
    while read line; do
        $first && {
            printf "ERROR($(basename ${scriptName})): dependency sorting error -- "
            first=false
        }
        printf "   ${line}\n"
    done >&2
}

get_sorted_kitnames() {
    get_kit_depends | tsort 2> >( format_tsort_errs ) | grep -v '^-$'
}

main() {
    #stub shellkit-loader-args "$@"
    [[ -n SHLOADER_DIR ]] && {
        cd $SHLOADER_DIR || die Failed to cd to $SHLOADER_DIR;
    } || {
        cd ${HOME}/.local/bin || die Failed to cd to ${HOME}/.local/bin
    }
    while read kit; do
        [[ -d ${kit} ]] || {
            echo "ERROR($(basename $scriptName)): shellkit ${kit} is referenced as a dependency but is not installed in ${PWD}"
            echo "   Run \"shpm install ${kit}\" to resolve this error."
            continue
        } >&2
        [[ -f ${kit}/${kit}.bashrc ]] && {
            echo "${kit}/${kit}.bashrc"
        }
    done < <(get_sorted_kitnames)
    true
}

[[ -z ${sourceMe} ]] && {
    case $1 in
        --version|-v) echo $SHELLKIT_LOADER_VER; exit 0;;
    esac
    main "$@"
    builtin exit
}
command true
