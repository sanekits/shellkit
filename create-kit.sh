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

fix_kitname() {
    set -x
    [[ -z $1 ]] && die fix_kitname.1  # Kitname text
    [[ -f $2 ]] || die fix_kitname.2  # script path
    local Kitname=$1
    local shpath=$2

    command sed -i -s "s%<Kitname>%${Kitname}%g" $shpath || die fix_kitname.3
}

main() {
    # Given:
    #   Cur dir is kit root
    #
    # Then:
    #   Create new kit elements

    [[ -d ./shellkit/.git ]] || die "main.0 Expected ./shellkit/.git to exist in $PWD"

    set -x  # This is not debugging!
    [[ -f make-kit.mk ]] || command cp shellkit/templates/make-kit.mk.template ./make-kit.mk || die

    command mkdir ./bin -p
    [[ -f ./bin/Kitname ]] && {
        kitname=$(cat ./bin/Kitname)
    } || {
        kitname=$(basename $PWD)
        [[ "$kitname" =~ ^[a-zA-Z][-a-zA-Z0-9_]+$ ]] || {
            die "main.3 Kitname contains invalid chars.  Change directory name to match requirements"
        }
        echo "$kitname" > ./bin/Kitname
    }
    (
        builtin cd ./bin && {
            command rsync -av ../shellkit/templates/bin/ ./ || die main.2
            (
                builtin cd shellkit \
                && command ln -sf ../../shellkit/setup-base.sh ./ \
                && command ln -sf ../../shellkit/realpath.sh ./
            ) || die main.2.3
            command mv kitname-version.sh ${kitname}-version.sh || die main.2.4
            fix_kitname $kitname ${kitname}-version.sh || die main.2.5
            command mv kitname.bashrc ${kitname}.bashrc || die main.2.6
            fix_kitname $kitname ${kitname}.bashrc || die main.2.7
        }
    )


    [[ -d .git ]] || {
        command git init || die main.4.1
        command git remote add upstream git@github.com:sanekits/${kitname} || die main.4.2
    }
    [[ -f .gitignore ]] || {
        echo -e "shellkit\ntmp" > .gitignore
    }
    local version='0.1.0'
    [[ -f version ]] || echo "${version}" > version
    [[ -f README.md ]] || initReadme "$kitname" "$version" > README.md

    command git add . || die main.9
    echo "$kitname created OK"
    true
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
