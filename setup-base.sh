#!/bin/bash
# setup-base.sh for shellkit

die() {
    echo "ERROR: $@" >&2
    exit 1
}

canonpath() {
    # Like "readlink -f", but portable
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}

reload_reqd=false

source ${scriptDir}/shellkit/shellkit_setup_base || die Failed sourcing shellkit_base

main_base() {
    [[ -z $Script ]] && die "\$Script not defined in main_base()"
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
    [[ -d ${scriptDir} ]] || die "bad scriptDir [$scriptDir]"
    command cp -r ${scriptDir}/* ./ || die "failed copying from ${scriptDir} to $PWD"
    builtin cd .. # Now were in .local/bin
    command ln -sf ./${Kitname}/${Kitname}-version.sh ./ || die "102.2"
    path_fixup_local_bin ${Kitname} || die "102.5"
    shrc_fixup || die "104"
    $reload_reqd && builtin echo "Shell reload required ('bash -l')" >&2
}

