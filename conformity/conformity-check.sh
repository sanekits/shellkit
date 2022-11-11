#!/bin/bash
# conformity-check.sh
# Runs in Docker during pre-publish phase to verify that the installed kit
# meets common feature and interface expectations.  See shellkit/docs/loader.md

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

run_localbin_checks() {
    local Kitname=$1
    (
        cd ~/.local/bin || die 101
        echo "~/.local/bin tests:"
        {
            local path_ok=false
            IFS=$':'; for p in $PATH; do
                [[ $p == ${HOME}/.local/bin ]] && { path_ok=true; break; }
            done; unset IFS
            [[ $path_ok ]] || die 101.5 ${HOME}/.local/bin is not on the PATH
            [[ -L ./${Kitname}-version.sh ]] || die 102 Missing ${Kitname}-version.sh;
            [[ $(./${Kitname}-version.sh) =~ [0-9]+\.[0-9]+\.[0-9]+$ ]] || die "$PWD/${Kitname}-version.sh returned unexpected output"
            [[ -x ./realpath.sh ]] || die 103 Missing ./realpath.sh;
            ini=${Kitname}/${Kitname}.bashrc
            [[ -f $ini ]] || die 104 Missing $ini
            PS1="::"
            source $ini || die 105 Failed sourcing $ini
            [[ $( type -t ${Kitname}-semaphore ) -eq function ]] || die 106 ${Kitname}-semaphore function missing
            (
                PS1="::"
                source ~/.bashrc
                [[ -n $SHELLKIT_LOADER_VER ]] || die "107 \$SHELLKIT_LOADER_VER not defined.  Is shellkit-loader.bashrc hooked in ~/.bashrc?"
            ) || exit 1

            grep -E "${Kitname}\.bashrc" ~/.bashrc && die "108 ${Kitname}.bashrc is mentioned in ~/.bashrc, this legacy hook should be removed."

        } 2>&1 | sed 's/^/  :/'
        # Let's ensure that shellkit-loader is sourced exactly once:
        local loader_count=$(grep -E 'source .*shellkit-loader\.bashrc' ${HOME}/.bashrc | wc -l )
        [[ $loader_count == 1 ]] || die "shellkit-loader.bashrc should be hooked exactly once in ~/.bashrc, not $loader_count times"
        echo
    ) || exit 1
}

main() {
    local Kitname
    while [[ -n $1 ]]; do
        case $1 in
            --kit) Kitname=$2; shift ;;
            *) die Unknown arg: "$*";;
        esac
        shift
    done

    # We run the installer twice, doing checks after each.  Expect that
    # idempotence is honored:
    tmp/latest.sh || die "Failed primary install test"
    run_localbin_checks $Kitname || die "Failed primary localbin checks"
    bash -l -c true || die "Failed primary shell init check"

    #echo "STUB SHELL:"; bash -l  # STUB to open a shell for inspection

    tmp/latest.sh || die "Failed secondary install test"
    run_localbin_checks $Kitname || die "Failed secondary localbin checks"
    bash -l -c true || die "Failed secondary shell init check"


    echo "${scriptName} completed: OK"
}


[[ -z ${sourceMe} ]] && {
    stub "${FUNCNAME[0]}.${LINENO}" "calling main()" "$@"
    main "$@"
    builtin exit
}
command true
