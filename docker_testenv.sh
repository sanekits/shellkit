#!/bin/bash
# docker_testenv.sh

die() {
    echo "ERROR: $*" >&2
    exit 1
}

nonroot_user=vscode  # Create this nonroot user (--user [name])
do_login=false # Login as nonroot_user?  (--login cmdline option)

make_nonroot_user() {
    [[ $UID == 0 ]] || return
    #su vscode bash true
    adduser --uid 1000 $nonroot_user --gecos "" --disabled-password
    echo "User $nonroot_user created"
}

install_requirements() {
    apt-get update || die apt-get update failed
    apt-get install -y vim-tiny
    [[ -f ${TEST_DIR}/container_prep.sh ]] && {
        echo "Running ${TEST_DIR}/container_prep.sh:"
        ${TEST_DIR}/container_prep.sh || die "Failed container_prep.sh"
    }
}

parse_args() {
    while [[ -n $1 ]]; do
        case $1 in
            --user)
                nonroot_user=$2
                shift
                ;;
            --login)
                do_login=true
                ;;
        esac
        shift
    done
    set +x
}

main() {
    echo "docker_testenv.sh args:[$*]"

    set -x
    parse_args "$@"
    set +x
    make_nonroot_user
    install_requirements

    echo "Entering test shell"
    cd /workspace
    set -x
    if $do_login; then
        su vscode  -c '/bin/bash --rcfile shellkit/docker-test-bashrc'
    else
        /bin/bash --rcfile shellkit/docker-test-bashrc
    fi
}

[[ -z ${sourceMe} ]] && main "$@"
