#!/bin/bash
# shellkit-loader.bashrc
# :vim filetype=sh :
#
#  This file should be hooked into the static shell init
# process, e.g. you could add this to ~/.bashrc:
#
#    source ~/.local/bin/shellkit-loader.bashrc
#
#  Normally this file is installed by shellkit automatically.

export SHELLKIT_LOADER_VER=5
export __shkit_loader_logfile="${TMPDIR:-/tmp}/shellkit-loader.log"

shellkit_loader() {
    # Load all shellkit init files (e.g. ~/.local/bin/<kit>/<kit>.bashrc),
    #  respecting kit dependencies.
    local loaderDir
    if [[ -f ./shellkit-loader.sh ]]; then
        loaderDir=$PWD
    else
        if [[ -f ${HOME}/.local/bin/shellkit-loader.sh ]]; then
            loaderDir=${HOME}/.local/bin
        else
            builtin echo "ERROR: can't find shellkit-loader.sh" >&2
            return;
        fi
    fi
    case ":${PATH}:" in
        *:"${HOME}/.local/bin":*)
            ;;
        *)
            PATH=${HOME}/.local/bin:$PATH
            ;;
    esac
    local initfile
    local loaderScript
    loaderScript=${loaderDir}/shellkit-loader.sh
    echo > "${__shkit_loader_logfile}"
    local orgDir=$PWD
    builtin cd "$loaderDir"  || return
    for initfile in $( SHLOADER_DIR="$loaderDir" ${loaderScript} ); do
        #shellcheck disable=1090
        echo "$(date '+%Y-%m-%dT%H:%M:%S.%3N%z') Load start file=${initfile}" >>"${__shkit_loader_logfile}"
        source "$initfile"
    done
    echo "$(date '+%Y-%m-%dT%H:%M:%S.%3N%z') Kit load done" >>"${__shkit_loader_logfile}"
    builtin cd "${orgDir}" || return
}

[[ -z ${SHELLKIT_LOAD_DISABLE:-} ]] && {
    shellkit_loader
}
