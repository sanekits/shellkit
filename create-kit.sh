#!/bin/bash
# create-kit.sh


[[ -x shellkit/realpath.sh ]] || die  $0 cannot find shellkit/realpath.sh

scriptName="$(command realpath.sh -f $0)"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR($(basename $scriptName)): $*" >&2
    builtin exit 1
}

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
    # Given:
    #  - a filename in the CURRENT dir containing template content
    # Then:
    #  - Replace all text matching <Kitname> with the kitname argument
    #  - Rename the file if it contains "kitname", substituting the kitname argument
    [[ -z $1 ]] && die fix_kitname.1  # Kitname text
    [[ -f $2 ]] || die fix_kitname.2  # script path
    local Kitname=$1
    local filename=$2

    [[ $filename == */* ]] && die "fix_kitname.3.1 filename argument must not contain dir elements"
    command sed -i -s "s%<Kitname>%${Kitname}%g" $filename || die fix_kitname.3
    local newFilename=$( echo "$filename" | command sed "s/kitname/${kitname}/g")
    [[ $newFilename == $(basename $filename) ]] && return  # No need to rename
    command mv $filename $newFilename || die "fix_kitname.4 mv failed"
}

main() {
    # Given:
    #   Cur dir is kit root
    #
    # Then:
    #   Create new kit elements

    [[ -d ./shellkit/.git ]] || die "main.0 Expected ./shellkit/.git to exist in $PWD"

    local shellkit_version=$(cat ./shellkit/version)

    set -x  # This is not debugging!

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
    [[ -f make-kit.mk ]] || {
        command cp shellkit/templates/make-kit.mk.template ./make-kit.mk || die main.1 failed copying make-kit.mk
        fix_kitname $kitname make-kit.mk || die main.1.4
    }
    (
        builtin cd ./bin && {
            command rsync -av ../shellkit/templates/bin/ ./ || die main.2
            (
                builtin cd shellkit \
                && command ln -sf ../../shellkit/setup-base.sh ./ \
                && command ln -sf ../../shellkit/realpath.sh ./
            ) || die main.2.3
            # Replace <Kitname> placeholder text and possibly rename files in the created it:
            for filename in kitname-version.sh kitname.bashrc kitname.sh _symlinks_ setup.sh; do
                fix_kitname $kitname $filename || die "main.2.5  processing ${filename} failed"
            done
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
    command git commit -m "Initial scaffolding from shellkit:${shellkit_version}" || die main 9.1
    builtin echo "00000000000000000000000000000000" > build-hash
    command git add build-hash && command git commit -m "Initial build-hash"
    command git tag ${version}
    echo "$kitname created OK"
    true
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
