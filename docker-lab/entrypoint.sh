#!/bin/bash
# entrypoint.sh for docker-lab

#shellcheck disable=2154
PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '

[[ $PWD == /workarea ]] || die 99

PostCreate=true

saveArgs=()
while [[ -n $1 ]]; do
    if [[ $1 == --no-postcreate ]]; then
        # Suppress invocation of kit's .docker-lab-postcreate target
        PostCreate=false
    else 
        saveArgs+=("$1")
    fi
    shift
done
set -- "${saveArgs[@]}"

git config --global --add safe.directory '*'

# Free exported helpers:  a few things that might make life easier in the docker shell.
#
#  Be aware that these entrypoint functions will not be available from shells created
# by other means on the same container.

jumpstart_ep() {
    # Convenience for debugging inside the container:
    {
        echo 'source /jumpstart.bashrc # added by jumpstart_ep ' 
        echo 'export _QUASH_BIN=/' 
        echo 'source /quash.bashrc' 
    } >> "${HOME}/.bashrc"
    ( 
        #shellcheck disable=1091
        source /jumpstart.bashrc \
          && vi_mode_on --noexec 
    )
    ln -sf /shared/bash_history "${HOME}/.bash_history"
    exec bash
}
export -f jumpstart_ep

if $PostCreate; then
    make .docker-lab-postcreate || :
fi


exec "$@"
