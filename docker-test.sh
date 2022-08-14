#!/bin/bash
# Test the current kit in a docker shell

die() {
    echo "ERROR: $@" >&2
    exit 1
}


canonpath() {
    type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    # Ok for rough work only.  Prefer realpath.sh if it's on the path.
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

Script=$(canonpath "$0")
Scriptdir=$(dirname -- "$Script")

cd ${Scriptdir}/..

getMounts() {
    builtin echo -n "-v $PWD:/workspace -v ${HOME}:/host_home:ro "
    [[ -d $TEST_DIR ]] && builtin echo -n " -v ${TEST_DIR}:/test_dir:ro"
}
getBaseImage() {
    if [[ -z https_proxy ]]; then
        echo "debian:latest"
    else
        docker image ls | grep -E "^.*dpkg-python-development-base\s*3.8" | awk '{print $1 ":" $2}'
    fi
}

getInnerArgs() {
    echo "--user vscode --login"
}

getEnvironment() {
    [[ -n $TEST_DIR ]] && echo -n " -e " TEST_DIR=/test_dir  # Because we mounted it there
    [[ -n $INNER_TEST_SCRIPT ]] && echo -n " -e " INNER_TEST_SCRIPT=${INNER_TEST_SCRIPT}
}

getInnerCmdline() {
    set -x
    echo "/workspace/shellkit/docker_testenv.sh $(getInnerArgs)"
    set +x
}

echo "Current dir: $(pwd -P)"
docker run $(getMounts) --rm --init -it $(getEnvironment) --name docker-test-$$ "$(getBaseImage)" bash -c "$(getInnerCmdline)" || die "docker_testenv.sh returned failure"

