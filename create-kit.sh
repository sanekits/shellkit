#!/bin/bash
# create-kit.sh

die() {
    builtin echo "ERROR: $*" >&2
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
    [[ -z $kitname ]] || die initReadme.1
    cat <<-EOF
#${kitname}

## Setup
  Download and install the self-extracting setup script:
    https://github.com/sanekits/${kitname}/releases/latest/downloads/${kitname}-setup-${version}.sh

  -- Or if [shellkit-pm]() is installed:
    `shpm install ${kitname}`

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
    [[ -f make-kit.mk ]] || cp shellkit/make-kit.mk.template ./make-kit.mk || die

    [[ -d ./bin ]] || mkdir ./bin || die

    [[ -f ./bin/Kitname ]] && {
        kitname=$(cat ./bin/Kitname)
    } || {
        kitname=$(basename $PWD)
        [[ "$kitname" =~ ^[a-zA-Z][-a-zA-Z0-9_]+$ ]] || {
            die "Kitname contains invalid chars.  Change directory name to match requirements"
         echo "$kitname" > ./bin/Kitname
        }
    }

    [[ -d .git ]] || {
        command git init || die
    }
    [[ -f .gitignore ]] || {
        echo "shellkit" > .gitignore
    }
    [[ -f version ]] || echo '0.1.0' > version
    [[ -f README.md ]] || initReadme > README.md

    true
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
