#!/bin/bash
# create-kit.sh

die() {
    builtin echo "ERROR($scriptName): $*" >&2
    builtin exit 1
}

[[ -x shellkit/realpath.sh ]] || die  $0 cannot find shellkit/realpath.sh

scriptName="$(command realpath.sh -f $0)"
scriptDir=$(command dirname -- "${scriptName}")


stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

initReadme() {
    set +x
    local kitname=$1
    local version=$2
    [[ -n $kitname ]] || die initReadme.1
    [[ -n $version ]] || die initReadme.2
    cat <<-EOF
# ${kitname}

## Setup

Download and install the self-extracting setup script:

    https://github.com/sanekits/${kitname}/releases/latest/downloads/${kitname}-setup-${version}.sh

Or **if** [shellkit-pm](https://github.com/sanekits/shellkit-pm) is installed:

    shpm install ${kitname}

##
EOF
}

main() {
    # Given:
    #   Cur dir is kit root
    #
    # Then:
    #   Create new kit elements

    [[ -d ./shellkit/.git ]] || die "Expected ./shellkit/.git to exist in $PWD"

    set -x  # This is not debugging!
    [[ -f make-kit.mk ]] || cp shellkit/templates/make-kit.mk.template ./make-kit.mk || die

    [[ -d ./bin ]] || mkdir ./bin || die

    [[ -f ./bin/Kitname ]] && {
        kitname=$(cat ./bin/Kitname)
    } || {
        kitname=$(basename $PWD)
        [[ "$kitname" =~ ^[a-zA-Z][-a-zA-Z0-9_]+$ ]] || {
            die "Kitname contains invalid chars.  Change directory name to match requirements"
        }
        echo "$kitname" > ./bin/Kitname
    }

    [[ -d .git ]] || {
        command git init || die
    }
    [[ -f .gitignore ]] || {
        echo "shellkit" > .gitignore
    }
    local version='0.1.0'
    [[ -f version ]] || echo "${version}" > version
    [[ -f README.md ]] || initReadme "$kitname" "$version" > README.md

    $kitname created OK
    true
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
