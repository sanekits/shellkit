#!/bin/bash
# version-bump.sh <version-file-path>
# Increment the version file path.  We only permit 1 digit per segment, so 0.0.9 wraps to 0.1.0, etc.

scriptName="$(readlink -f "$0")"
#shellcheck disable=2154
PS4='$( _0=$?; exec 2>/dev/null; realpath -- "${BASH_SOURCE[0]:-?}:${LINENO} ^$_0 ${FUNCNAME[0]:-?}()=>" ) '

die() {
    builtin echo "ERROR($(basename "${scriptName}")): $*" >&2
    builtin exit 1
}


main() {
    [[ $# -gt 0 ]] \
        || die "Expected <version-file-path>"

    verFile=$1
    [[ -f $verFile ]] \
        || die "Can't find $verFile"

    oldVersion=$(cat "$verFile")

    [[ "$oldVersion" =~ ^[0-9]\.[0-9]\.[0-9]$ ]] \
        || die "Old version does not match format requirements: [$oldVersion]"

    IFS=$'.' ; read -r major minor patch <<< "$oldVersion"; unset IFS
    if (( ++patch > 9 )); then
        patch=0
        if (( ++minor > 9 )); then
            minor=0
            if (( ++major > 9 )); then
                die "No more versions available after 9.9.9!"
            fi
        fi
    fi
    newVersion="$major.$minor.$patch"
    echo "$newVersion" > "$verFile" || die "Failed updating $verFile"
    echo "New version: $newVersion"
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
