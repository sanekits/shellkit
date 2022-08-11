#!/bin/bash
# Test the current kit in a docker shell

die() {
    echo "ERROR: $@" >&2
    exit 1
}

canonpath() {
    # Like "readlink -f", but portable
    ( cd -L -- "$(command dirname -- ${1})"; echo "$(command pwd -P)/$(command basename -- ${1})" )
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
    echo "debian"
}

getInnerArgs() {
    echo "--user vscode --login"
}

getEnvironment() {
    [[ -n $TEST_DIR ]] && echo -n " -e " TEST_DIR=/test_dir  # Because we mounted it there
    [[ -n $INNER_TEST_SCRIPT ]] && echo -n " -e " INNER_TEST_SCRIPT=${INNER_TEST_SCRIPT}
}

getInnerCmdline() {
    echo "/workspace/shellkit/docker_testenv.sh $(getInnerArgs)"
}

echo "Current dir: $(pwd -P)"
docker run $(getMounts) --rm -it $(getEnvironment) --name docker-test-$$ "$(getBaseImage)" bash -c "$(getInnerCmdline)" || die "docker_testenv.sh returned failure"

