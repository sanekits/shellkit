# shellkit-loader.bashrc
#
#  This file should be hooked into the static shell init
# process, e.g. you could add this to ~/.bashrc:
#
#    source ~/.local/bin/shellkit-loader.bashrc
#
#  Normally this file is installed by shellkit automatically.

SHELLKIT_LOADER_VER=1

shellkit_loader() {
    # Load all shellkit init files (e.g. ~/.local/bin/<kit>/<kit>.bashrc),
    #  respecting kit dependencies.
    local loaderDir
    [[ -f ./shellkit-loader.sh ]] && {
        loaderDir=$PWD
    } || {
        [[ -f ${HOME}/.local/bin/shellkit-loader.sh ]] && {
            loaderDir=${HOME}/.local/bin
        } ||  {
            echo "ERROR: can't find shellkit-loader.sh"
            return;
        }
    }
    local initfile
    local loaderScript
    loaderScript=${loaderDir}/shellkit-loader.sh
    for initfile in $( SHLOADER_DIR="$loaderDir" ${loaderScript} ); do
        source "$initfile"
    done
}

[[ -z $SHELLKIT_LOAD_DISABLE ]] && {
    shellkit_loader
}
