#!/bin/bash
# publish/publish-via-github-release.sh

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

canonpath() {
    type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    # Ok for rough work only.  Prefer realpath.sh if it's on the path.
    ( cd -L -- "$(dirname -- $1)"; echo "$(pwd -P)/$(basename -- $1)" )
}

Script=$(canonpath "$0")
Scriptdir=$(command dirname "$Script")

#stub Script=${Script} Scriptdir=${Scriptdir}
Kitname=$( command cat $(canonpath ${Scriptdir}/../bin/Kitname ))

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

checkTag() {
    # verify existence of local tag matching version
    local version=$1
    [[ -z $version ]] && die "No version passed to checkTag"

    version="${version//./\~}"
    command git tag | command sed 's/\./~/g' | command grep "${version}" || {
        builtin echo "No git tag with version $1" >&2
        false
        return
    }
    true
}

if [[ -z $sourceMe ]]; then
    [[ -n $Kitname ]] || die 99
    builtin cd ${Scriptdir}/../bin || die 100
    [[ -z $rawPublish ]] && {
            if [[ $( command git status -s .. | command wc -l 2>/dev/null) -gt 0 ]]; then
            die "One or more files in $PWD need to be committed before publish"
        fi
    }
    command git rev-parse HEAD > ./hashfile || die 104
    builtin cd ${Scriptdir}/.. || die 101
    version=$( bin/${Kitname}-version.sh | cut -f2)
    [[ -z $version ]] && die 103
    checkTag  ${version} || die 103.4

    command mkdir -p ./tmp

    destFile=$PWD/tmp/${Kitname}-setup-${version}.sh
    command makeself.sh --follow --base64 $PWD/bin $destFile "${Kitname} ${version}" ./setup.sh  || die # [src-dir] [dest-file] [label] [setup-command]
    (
        cd $(dirname $destFile) && ln -sf $(basename $destFile) latest.sh
    )
    [[ $? -eq 0 ]] && echo "Done: upload $PWD/tmp/${Kitname}-setup-${version}.sh to Github release page (https://github.com/sanekits/${Kitname}/releases)"
fi
