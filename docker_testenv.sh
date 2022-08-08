#!/bin/bash
# docker_testenv.sh

die() {
    echo "ERROR: $*" >&2
    exit 1
}

nonroot_user=vscode

make_nonroot_user() {
    [[ $UID == 0 ]] || return
    su vscode bash true
    adduser --uid 1000 vscode --gecos "" --disabled-password
    echo "User vscode created"

}

main() {
    echo "docker_testenv.sh args:[$*]"

    make_nonroot_user

    echo "Entering test shell"
    cd /workspace
    su vscode -c /bin/bash
}

[[ -z ${sourceMe} ]] && main "$@"
