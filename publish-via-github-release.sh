#!/bin/bash
# publish/publish-via-github-release.sh


Script=$(command readlink -f $0)
scriptDir=$(command dirname $Script)
Kitname=$(cat $(readlink -f ${scriptDir}/../bin/Kitname))


die() {
    builtin echo "ERROR: $@" >&2
    builtin exit 1
}

if [[ -z $sourceMe ]]; then
    [[ -n $Kitname ]] || die 99
    builtin cd ${scriptDir}/../bin || die 100
    if [[ $( command git status -s .. | command wc -l 2>/dev/null) -gt 0 ]]; then
        die "One or more files in $PWD need to be committed before publish"
    fi
    command git rev-parse HEAD > ./hashfile || die 104
    builtin cd ${scriptDir}/.. || die 101
    version=$( bin/${Kitname}-version.sh | cut -f2)
    [[ -z $version ]] && die 103

    command mkdir -p ./tmp

    destFile=$PWD/tmp/${Kitname}-setup-${version}.sh
    command makeself.sh --follow --base64 $PWD/bin $destFile "${Kitname} ${version}" ./setup.sh  || die # [src-dir] [dest-file] [label] [setup-command]
    (
        cd $(dirname $destFile) && ln -sf $(basename $destFile) latest.sh
    )
    [[ $? -eq 0 ]] && echo "Done: upload $PWD/tmp/${Kitname}-setup-${version}.sh to Github release page (https://github.com/sanekits/${Kitname}/releases)"
fi
