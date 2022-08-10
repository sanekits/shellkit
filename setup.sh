#!/bin/bash
# setup.sh for shellkit

die() {
    echo "ERROR: $@" >&2
    exit 1
}

canonpath() {
    # Like "readlink -f", but portable
    ( cd -L -- "$(command dirname -- ${1})"; echo "$(command pwd -P)/$(command basename -- ${1})" )
}

Script=$(canonpath "$0")
Scriptdir=$(dirname -- "$Script")
reload_reqd=false

source ${Scriptdir}/shellkit/shellkit_setup_base || die Failed sourcing shellkit_base

main() {
    if [[ ! -d $HOME/.local/bin/${Kitname} ]]; then
        if [[ -e $HOME/.local/bin/${Kitname} ]]; then
            die "$HOME/.local/bin/${Kitname} exists but is not a directory.  Refusing to overwrite"
        fi
        command mkdir -p $HOME/.local/bin/${Kitname} || die "Failed creating $HOME/.local/bin/${Kitname}"
    fi
    if [[ $(inode $Script) -eq $(inode ${HOME}/.local/bin/${Kitname}/setup.sh) ]]; then
        die "cannot run setup.sh from ${HOME}/.local/bin"
    fi
    builtin cd ${HOME}/.local/bin/${Kitname} || die "101"
    command rm -rf ./* || die "102"
    [[ -d ${Scriptdir} ]] || die "bad Scriptdir [$Scriptdir]"
    command cp -r ${Scriptdir}/* ./ || die "failed copying from ${Scriptdir} to $PWD"
    builtin cd .. # Now were in .local/bin
    command ln -sf ./${Kitname}/${Kitname}-version.sh ./ || die "101.5"
    command ln -sf ./${Kitname}/parse_ps1_host_suffix.sh ./ || die "101.6"
    path_fixup_local_bin ${Kitname} || die "102"
    shrc_fixup || die "104"
    $reload_reqd && builtin echo "Shell reload required ('bash -l')" >&2
}

[[ -z $sourceMe ]] && main "$@"
