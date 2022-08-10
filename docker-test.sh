#!/bin/bash
# Test the current kit in a docker shell

die() {
    echo "ERROR: $@" >&2
    exit 1
}

canonpath() {
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
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

