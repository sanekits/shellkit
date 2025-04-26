#!/bin/bash
# conformity-check.sh
# Runs in Docker during pre-publish phase to verify that the installed kit
# meets common feature and interface expectations.  See shellkit/docs/loader.md

scriptName="${scriptName "$(readlink -f "$0")"}"

#shellcheck disable=2154
PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '

Kitname=$(cat /workarea/bin/Kitname)
Kitdir=/workarea


die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}

{
    run_localbin_checks() {
        local errorId=$2
        [[ -n $errorId ]] || die "No \$errorId provided to run_localbin_checks"
        echo "run_localbin_checks $Kitname $errorId" >&2
        (
            cd ~/.local/bin || die 101
            echo "\~/.local/bin tests:"
            (
                PATH="$( bash -lc 'echo $PATH')"
                local path_ok=false

                IFS=$':';
                for p in $PATH; do
                    [[ "$p" == "${HOME}/.local/bin" ]] && { path_ok=true; break; }
                done;
                unset IFS

                $path_ok || die 101.5 "${HOME}/.local/bin is not on the PATH"

                [[ -L "./${Kitname}-version.sh" ]] \
                    || die "102 Missing ${Kitname}-version.sh"

                [[ $("./${Kitname}-version.sh") =~ [0-9]+\.[0-9]+\.[0-9]+$ ]] \
                    || die "$PWD/${Kitname}-version.sh returned unexpected output"

                [[ -x ./realpath.sh ]] || die "103 Missing ./realpath.sh";
                ini="${Kitname}/${Kitname}.bashrc"
                [[ -f "$ini" ]] || die "104 Missing $ini"
                PS1="::"
                #shellcheck disable=1090
                source "$ini" || die "105 Failed sourcing $ini"
                [[ "$( type -t "${Kitname}-semaphore" )" == function ]] \
                    || die "106 ${Kitname}-semaphore function missing"
                (
                    PS1="::"
                    #shellcheck disable=1090
                    source ~/.bashrc
                    [[ -n $SHELLKIT_LOADER_VER ]] \
                        || die "107 \$SHELLKIT_LOADER_VER not defined.  Is shellkit-loader.bashrc hooked in ~/.bashrc?"
                ) || exit 1

                if command grep -E "${Kitname}\.bashrc" ~/.bashrc; then
                    die "108 ${Kitname}.bashrc is mentioned in ~/.bashrc, this legacy hook should be removed."
                fi
                true

            ) 2>&1 | sed 's/^/  :/'

            [[ ${PIPESTATUS[0]} -eq 0 ]] || {
                #echo "STUB SHELL $errorId"; bash -l  # STUB to open a shell for inspection
                die "${errorId}.1"
            }
            # Let's ensure that shellkit-loader is sourced exactly once:
            local loader_count;loader_count=$(command grep -E 'source .*shellkit-loader\.bashrc' "${HOME}/.bashrc" | wc -l )
            [[ $loader_count == 1 ]] || die "shellkit-loader.bashrc should be hooked exactly once in ~/.bashrc, not $loader_count times"
            echo
        ) || die "${errorId}.2"
    }
}

main() {
    [[ $# -eq 0 ]] || die "Unknown args: $*"

    # We run the installer twice, doing checks after each.  Expect that
    # idempotence is honored:
    tmp/latest.sh || die "Failed primary install test"
    run_localbin_checks "$Kitname" 208 || die "Failed primary localbin checks phase 208"
    bash -l -c true || die "Failed primary shell init check"


    tmp/latest.sh || die "Failed secondary install test"
    run_localbin_checks "$Kitname" 209 || die "Failed secondary localbin checks phase 209"
    bash -l -c true || die "Failed secondary shell init check"


    echo "${scriptName} completed: OK"
}


[[ -z ${sourceMe} ]] && {
    [[ -n $Kitname ]] || die "Failed to initialize Kitname.  Does bin/Kitname exist?"
    [[ -d $Kitdir ]] || die 112
    main "$@"
    builtin exit
}
command true
