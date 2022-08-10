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

Script=$(canonpath "$0")
Scriptdir=$(dirname -- "$Script")

cd ${Scriptdir}/..

getMounts() {
    echo "-v $PWD:/workspace -v ${HOME}:/host_home:ro"
}
getBaseImage() {
    echo "debian"
}

getInnerArgs() {
    echo "--user vscode --login"
}
getInnerCmdline() {
    echo "/workspace/shellkit/docker_testenv.sh $(getInnerArgs)"
}

docker run $(getMounts) --rm -it --name docker-test-$$ "$(getBaseImage)" bash -c "$(getInnerCmdline)" || die "docker_testenv.sh returned failure"

