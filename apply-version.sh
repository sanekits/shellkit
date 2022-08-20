#!/bin/bash
# apply-version.sh

scriptName="$(command readlink -f $0)"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR($(basename -- $scriptName)): $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}


update_readme_version() {
    local kitname="$1"
    local version="$2"
    command sed  -i.bak -e "s%${kitname}-setup-[0-9]\.[0-9]\.[0-9]\.sh%${kitname}-setup-${version}.sh%" ./README.md
}

update_version_script() {
    local kitname="$1"
    local version="$2"

    command sed  -i.bak -e "s%KitVersion=[0-9]\.[0-9]\.[0-9]%KitVersion=${version}%" bin/${kitname}-version.sh
}

main() {
    set -x
    local version=$(cat version)
    local kitname=$(cat bin/Kitname)
    [[ -n $version ]] || die bad version
    [[ -n $kitname ]] || die bad kitname
    [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "bad version: \"$version\""
    update_readme_version $kitname $version || die main.3
    set -x
    update_version_script $kitname $version || die main.4
    true
}

[[ -z ${sourceMe} ]] && main "$@"
