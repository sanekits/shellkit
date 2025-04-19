#!/bin/bash
# entrypoint.sh for docker-lab

echo hello >&2

[[ $PWD == /workarea ]] || die 99

git config --global --add safe.directory '*'

# Free exported helpers:  a few things that might make life easier in the docker shell.
#
#  Be aware that these entrypoint functions will not be available from shells created
# by other means on the same container.

jumpstart_ep() {
    #shellcheck disable=1091
    echo 'source /host_home/dotfiles/jumpstart.bashrc # added by jumpstart_ep ' >> "${HOME}/.bashrc"
    exec bash
}
export -f jumpstart_ep

make .docker-lab-postcreate || :


exec "$@"
