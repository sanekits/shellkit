#!/bin/bash
# docker_testenv.sh

die() {
    echo "ERROR: $*" >&2
    exit 1
}

scriptName=$(readlink -f -- $0)
scriptDir=$(dirname -- $scriptName)

stubShell() {
    echo "stubShell: do exit to continue" >&2
    bash
}

export nonroot_user=vscode  # Create this nonroot user (--user [name])
do_login=false # Login as nonroot_user?  (--login cmdline option)

bashrc_content() {
    cat <<-EOF
# .bashrc generated by bashrc_content()
set -o vi

EOF
}


make_nonroot_user() {
    [[ $UID == 0 ]] || return

    if [[ "$(type -t yum)" == *file* ]];  then
        # Redhat
        adduser --uid 1000 $nonroot_user

    else
        # Debian:
        adduser --uid 1000 $nonroot_user --gecos "" --disabled-password || {
            die "adduser failed ${scriptName}";
        }
    fi
    bashrc_content > /home/${nonroot_user}/.bashrc
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
}

main() {
    echo "docker_testenv.sh args:[$*]"

    parse_args "$@"
    make_nonroot_user
    install_requirements

    echo "Entering test shell"
    cd /workspace
    if $do_login; then
        su vscode  -c '/bin/bash --rcfile shellkit/docker-test-bashrc'
    else
        /bin/bash --rcfile shellkit/docker-test-bashrc
    fi
}

[[ -z ${sourceMe} ]] && main "$@"
