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
    command sed  -i -e "s%${kitname}-setup-[0-9]\.[0-9]\.[0-9]\.sh%${kitname}-setup-${version}.sh%" ./README.md
}

main() {
    set -x
    local version=$(cat version)
    local kitname=$(cat bin/Kitname)
    [[ -n $version ]] || die bad version
    [[ -n $kitname ]] || die bad kitname
    update_readme_version $kitname $version || die main.3
    true
}

[[ -z ${sourceMe} ]] && main "$@"
