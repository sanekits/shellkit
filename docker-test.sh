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

docker run -v $PWD:/workspace --rm -it debian bash -c /workspace/shellkit/docker_testenv.sh || die "docker_testenv.sh returned failure"

