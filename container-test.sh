#!/bin/bash
# container-test.sh

#  Starts a container for testing by launching a shellkit-component process.
#
#   Example:
#      Command='echo hello' \
#        container-test.sh --component shellkit-conformity --keep-shell
#
#   - See $ShellkitWorkspace/.devcontainer/shellkit-component.mk
#
#   - Mounts :
#      - temp dir on the host into ~/.local/bin of the container so that
#        changes applied by a kit installer can be easily inspected / compared from
#        the host side
#      - PWD:/workspace:ro
#
#   - Env:
#       Command="command line" # to launch process when container is started, or defaults to shell
#
#   - Args:
#       --component:  # basename of the component, e.g. shellkit-conformity, shellkit-pytest, etc.
#       --keep-shell,-k:  # Stay in the container shell instead of exiting after command

scriptName="$(readlink -f "$0")"
#shellcheck disable=2154
PS4='$( exec 2>/dev/null; set +u; bx="${BASH_SOURCE[0]:-_unk_}"; [[ -z "$bx" ]] || realpath -- "$bx" || echo "$bx"):${LINENO} +$? ${FUNCNAME[0]:+${FUNCNAME[0]}()| }'

setShellkitWorkspace() {
    local xd=$PWD
    while [[ $xd != / ]]; do
        [[ -f ${xd}/.shellkit-workspace ]] && { ShellkitWorkspace=$xd; return; }
        xd=$(dirname -- "$xd")
    done
}
setShellkitWorkspace
KeepShell=false

set -ue
ComponentDockerMakefile=${ShellkitWorkspace}/.devcontainer/shellkit-component.mk
Component=
Read_only_workspace=":ro"

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}

stub() {
    # Print debug output to stderr.  Recommend to call like this:
    #   stub "${FUNCNAME[0]}.${LINENO}" "$@" "<Put your message here>"
    #
    set +u
    [[ -n $NoStubs ]] && { set -u; return; }
    [[ -n $__stub_counter ]] && (( __stub_counter++  )) || __stub_counter=1
    {
        builtin printf "  <=< STUB(%d:%s)" "$__stub_counter" "$(basename "$scriptName")"
        builtin printf "[%s] " "$@"
        builtin printf " >=> \n"
    } >&2
    set -u
}

main() {
    [[ -f $ComponentDockerMakefile ]] \
        || die 100

    # Create/update the image:
    make -f "${ComponentDockerMakefile}" "Component=${Component}" image \
        || die "102 image create failed"

    # Prepare the fake .local/bin:
	local tmpLocalBin; tmpLocalBin=$( mktemp -d -p /tmp fakelocalbin-XXXXX )
    mkdir -p "$tmpLocalBin"
    chown "$(id -u):$(id -u)" "$tmpLocalBin" \
        || die 103 bad chown
    chmod oug+rx "$tmpLocalBin" \
        || die 104 bad chown
    command rm "$(dirname "$tmpLocalBin")/fakelocalbin-latest" &>/dev/null \
        || true
    ln -sf "$tmpLocalBin" "$(dirname "$tmpLocalBin")/fakelocalbin-latest" \
        || die 105 bad ln

    # Create+launch the container:
	local volumes="-v ${PWD}:/workspace${Read_only_workspace}  \
        -v ${tmpLocalBin}:/home/vscode/.local/bin  \
        -v ${ShellkitWorkspace}:/shellkit-workspace"
    echo "Command=${Command}"
    echo "Component=${Component}"
    make -f "${ComponentDockerMakefile}" \
        Volumes="${volumes}" \
        Component="${Component}" \
        Command="${Command}"  \
        run

}

set +u
[[ -z ${sourceMe} ]] && {
    while [[ -n $1 ]]; do
        case $1 in
            --component) shift; Component="$1";;
            --keep-shell|-k) KeepShell=true ;;
            --writeable-workspace|-w)  Read_only_workspace="" ;;
            *) die "Unknown arg: $1";;
        esac
        shift
    done
    set -u
    [[ $# -eq 0 ]] \
        || die "Unknown args: $*"
    [[ -n $Component ]] \
        || die "No --component [name] specified"

    set +u;
    $KeepShell \
        && [[ -n $Command ]] \
            && Command="${Command}; bash"
    [[ -n $Command ]] \
        || Command=bash;
    set -u

    main
    builtin exit
}
command true
