#!/bin/bash
# setup.sh for <Kitname>
#  This script is run from a temp dir after the self-install code has
# extracted the install files.   The default behavior is provided
# by the main_base() call, but after that you can add your own logic
# and installation steps.


# The shellkit/ tooling naturally evolves out from under the dependent kits.  ShellkitSetupVers allows
# detecting the need for refresh of templates/* derived files.  To bump the root version, 
# zap all templates/* containing 'ShellkitTemplateVers' constants and changes to the corresponding dependent kits
# Note that within templates/* there may be diverse versions in upstream shellkit, they don't all have to match,
# but the derived copies should be sync'ed with upstream as needed.

#shellcheck disable=2154
PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '
#shellcheck disable=2034
ShellkitTemplateVers=3

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
    ( builtin cd -L -- "$(command dirname -- "$0")" || exit; builtin echo "$(command pwd -P)/$(command basename -- "$0")" )
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}
scriptName="${scriptName:-"$(canonpath  "$0")"}"
scriptDir=$(command dirname -- "${scriptName}")

#shellcheck disable=1091
source "${scriptDir}/shellkit/setup-base.sh"


die() {
    builtin echo "ERROR(setup.sh): $*" >&2
    builtin exit 1
}

main() {
    Script=${scriptName} main_base "$@"
    builtin cd "${HOME}/.local/bin" || die 208
    # TODO: kit-specific steps can be added here




    # FINALIZE: perms on ~/.local/bin/<Kitname>.  We want others/group to be
    # able to traverse dirs and exec scripts, so that a source installation can
    # be replicated to a dest from the same file system (e.g. docker containers,
    # nfs-mounted home nets, etc)
    command chmod og+rX "${HOME}/.local/bin/${Kitname:-_unk_}" -R
    command chmod og+rX "${HOME}/.local" "${HOME}/.local/bin"
    true
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
