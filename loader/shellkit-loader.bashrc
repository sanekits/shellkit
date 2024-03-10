# shellkit-loader.bashrc
# :vim filetype=sh :
#
#  This file should be hooked into the static shell init
# process, e.g. you could add this to ~/.bashrc:
#
#    source ~/.local/bin/shellkit-loader.bashrc
#
#  Normally this file is installed by shellkit automatically.

export SHELLKIT_LOADER_VER=4

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
            builtin echo "ERROR: can't find shellkit-loader.sh" >&2
            return;
        }
    }
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
    local orgDir=$PWD
    builtin cd "$loaderDir"
    for initfile in $( SHLOADER_DIR="$loaderDir" ${loaderScript} ); do
        source "$initfile"
    done
    builtin cd ${orgDir}
}

[[ -z $SHELLKIT_LOAD_DISABLE ]] && {
    shellkit_loader
}
