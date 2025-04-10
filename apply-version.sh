#!/bin/bash
# apply-version.sh

scriptName="$(command readlink -f "$0")"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR($(basename -- "$scriptName")): $*" >&2
    builtin exit 1
}

#shellcheck disable=1091
sourceMe=1 source "${scriptDir}/sedxi" || die "0.1"

stub() {
    # Print debug output to stderr.  Call like this:
    #   stub "${FUNCNAME[0]}.${LINENO}" "$@" "<Put your message here>"
    #
    builtin echo -n "  <<< STUB" >&2
    for arg in "$@"; do
        echo -n "[${arg}] " >&2
    done
    echo " >>> " >&2
}


update_readme_version() {
    local kitname="$1"
    local version="$2"
    sedxi ./README.md -e "s%${kitname}-setup-[0-9]\.[0-9]\.[0-9]\.sh%${kitname}-setup-${version}.sh%" -e "s%[0-9]\.[0-9]\.[0-9]%${version}%g"
}

update_version_script() {
    local kitname="$1"
    local version="$2"

    sedxi  "bin/${kitname}-version.sh" -e "s%KitVersion=[0-9]\.[0-9]\.[0-9]%KitVersion=${version}%"
}

update_version_generic() {
    # Replace <Kitname> with $1 and N.N.N with $2 for all files
    # in [$3..)
    local kitname="$1"
    local version="$2"
    shift 2
    for file in "$@"; do
        sedxi "${file}" -e "s%<Kitname>%${kitname}%g" -e "s%[0-9]\.[0-9]\.[0-9]%${version}%g"
    done
}

main() {
    local version kitname
    local caller_file_list=()

    while [[ -n $1 ]]; do
        case $1 in
            --version)
                version=$2
                shift
                ;;
            --kitname)
                kitname=$2
                shift
                ;;
            -*)
                die "unknown option(s): $*"
                ;;
            *)
                caller_file_list+=( "$1" )
                ;;
        esac
        shift
    done
    [[ -n $version ]] || {
        version=$(cat version)
    }
    [[ -n $kitname ]] || {
        kitname=$(cat bin/Kitname 2>/dev/null)
    }
    [[ -n $version ]] || die bad version
    [[ -n $kitname ]] || {
        # Sometimes you don't need kitname.  But if you do and don't provide it
        # we must make that obvious:
        kitname="UNDEFINED_KITNAME_IN_APPLY_VERSION_SH"
    }
    [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "bad version: \"$version\""
    [[ -f README.md ]] && {
        update_readme_version "$kitname" "$version" || die main.3
    }
    [[ -f bin/${kitname}-version.sh ]] && {
        update_version_script "$kitname" "$version" || die main.4
    }
    update_version_generic "$kitname" "$version" "${caller_file_list[@]}" || die main.5
    true
}

[[ -z ${sourceMe} ]] && {
    main "$@"
}
