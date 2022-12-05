#!/bin/bash
# setup-base.sh for shellkit.  Source this from the kit's own setup.sh

PS4='\033[0;33m+(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

die() {
    echo "ERROR(setup-base.sh): $@" >&2
    exit 1
}

die2() {
    echo "ERROR(2,setup-base.sh): $@" >&2
    exit 2
}

canonpath() {
    builtin type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    builtin type -t readlink &>/dev/null && {
        command readlink -f "$@"
        return
    }
    # Fallback: Ok for rough work only, does not handle some corner cases:
    ( builtin cd -L -- "$(command dirname -- $0)"; builtin echo "$(command pwd -P)/$(command basename -- $0)" )
}

reload_reqd=false

[[ -z $scriptDir ]] && die "\$scriptDir not defined. This must be set by outer script"
read Kitname _ < "${scriptDir}/Kitname"
[[ -z $Kitname ]] && die "\$Kitname not defined"

inode() {
    # Returns inode of $1
    ( command ls -i "$1" | command awk '{print $1}') 2>/dev/null
}

is_on_path() {
    # Return true if $1 is on the PATH
    local tgt_dir="$1"
    [[ -z $tgt_dir ]] && { true; return; }
    local vv=( $(echo "${PATH}" | tr ':' '\n') )
    for v in "${vv[@]}"; do
        if [[ $tgt_dir == "$v" ]]; then
            return
        fi
    done
    false
}

localbin_semaphore() {
    cat <<-EOF
#!/bin/sh
true
EOF
}

path_fixup_local_bin() {
    # Add ~/.local/bin to the PATH if it's not already.  Modify
    # either .bash_profile or .profile honoring bash startup rules.
    local kitname="${1}"
    [[ -z $kitname ]] && kitname="shellkit"
    ( # Create a semaphore script in ~/.local/bin.  If we can run it without specifying path, we're good.
        builtin cd
        semaphore=_semaphore_$$
        mkdir -p ${HOME}/.local/bin
        [[ -d ${HOME}/.local/bin ]] || die2 "Failed to create ${HOME}/.local/bin"
        localbin_semaphore > ${HOME}/.local/bin/${semaphore}
        command chmod +x ~/.local/bin/${semaphore}
        if ! command bash -l -c "${semaphore}" &>/dev/null; then
            exit 1  # .local/bin is not on the PATH
        fi
        rm ~/.local/bin/${semaphore}
        true # .local/bin is already on the PATH
    ) && { true; return; }
    [[ $? -eq 2 ]] && die "path_fixup_local_bin failed"
    echo "~/.local/bin is not on the path. Fixing profile." >&2
    (
        local profile=.bash_profile
        [[ -f ${HOME}/${profile} ]] || profile=.profile
        tmp_profile="profile-tmp.$$"
        echo "export PATH=\${HOME}/.local/bin:\$PATH # Added by ${kitname}" > "${tmp_profile}" || die2 3092
        [[ -e ~/${profile} ]] && cat ~/${profile} >> "${tmp_profile}"
        mv "$tmp_profile" ~/${profile} || die 203
        echo "WARNING: ${HOME}/.local/bin was added to your PATH by modifying ~/${profile}.  (Using this dir is a normal convention, but changes to the PATH can sometimes produce unwanted side-effects.)" >&2
    ) || die

    reload_reqd=true
}

shrc_fixup() {
    # We must ensure that ~/.bashrc sources shellkit-loader.bashrc exactly once.
    case $- in
        *i*) ;;
        *) die "shrc_fixup() must run in an interactive shell"
    esac
    (
        PS1="::" source ~/.bashrc
        [[ -n "$SHELLKIT_LOADER_VER" ]] && exit 0

         # Add hook into .bashrc
        echo "[[ -f \${HOME}/.local/bin/shellkit-loader.bashrc ]] && source \${HOME}/.local/bin/shellkit-loader.bashrc # Added by shellkit (${Kitname}-setup.sh)" >> ${HOME}/.bashrc

    ) || { false; return; }
    (
        # Verify that it took:
        PS1=":::" source ~/.bashrc;
        [[ -n $SHELLKIT_LOADER_VER ]] || die "Failed shellkit-loader.bashrc hook installation"
    )
    reload_reqd=true
}

run_bashrc_hook() {
    # We must force bash to re-invoke our own script in interactive mode
    # to ensure that .bashrc loads -- otherwise an early-exit check of $- could spoil
    # the hook test
    bash -i $Script --run-bashrc-hook
}

install_symlinks() {
    # When:
    #   pwd=~/.local/bin
    #   and ${Kitname} is defined
    #   and ./${Kitname}/_symlinks_ exists
    # Then:
    #   make symlink in . for each name in ${Kitname}/_symlinks_
    [[ -f ./${Kitname}/_symlinks_ ]] || { true; return; }
    builtin read -a symlinks < <( command sed -e 's/#.*//'  ./${Kitname}/_symlinks_ | command tr '\n' ' ' )
    for item in ${symlinks[*]}; do
        command ln -sf ${Kitname}/${item} "./$(basename -- ${item})" || die "Failed installing symlink ${item}"
        #echo "Symlink installed for: ${item}"
    done
}

version_lt() {
    # Returns true if left < right for 3-tuple version numbers
    (
        IFS="." read  l0 l1 l2 <<< "$1"
        IFS="." read  r0 r1 r2 <<< "$2"
        (( $l0 < $r0 )) && exit
        (( $l0 == $r0 )) || exit
        (( $l1 < $r1 )) && exit
        (( $l1 == $r1 )) || exit
        (( $l2 < $r2 )) && exit
        false
    )
}

install_realpath_sh() {
    # When:
    #   pwd=~/.local/bin
    #   and ${Kitname} is defined
    #   and ${Kitname}/shellkit/realpath.sh exists
    #   and ./realpath.sh !exists OR ./realpath.sh is lower version
    # Then:
    #   copy ${Kitname}/shellkit/realpath.sh to ./realpath.sh
    local ourVers="$( ${Kitname}/shellkit/realpath.sh --version )"
    [[ -n $ourVers ]] || return $(die "Failed testing realpath.sh version in kit")
    [[ -f ./realpath.sh ]] && {
        # Is the installed version > our version?
        local installedVers="$( ./realpath.sh --version )"
        [[ -n "$installedVers" ]] && {
            if version_lt "$ourVers" "$installedVers"; then
                echo "Installed version of realpath.sh is newer than ours, skipping."
                return
            fi
        }
    }
    command cp ${Kitname}/shellkit/realpath.sh ./realpath.sh || die "Failed installing realpath.sh"
}


ensure_HOME() {
    [[ -n $HOME ]] && [[ -d $HOME ]] && { true; return; }
    [[ $UID == 0 ]] && { export HOME=/root; return; }
    [[ -d /home/$(whoami) ]] && { export HOME=/home/$(whoami); return; }
    die "ensure_HOME() failed"
}

fixup_local_bin_perms() {
    [[ -d ${HOME}/.local/bin ]] || { true; return; }
    command chmod oug+rx ${HOME}/.local/bin || return $(die "Failed setting +rx on ~/.local/bin")
    command chmod oug+rx ${HOME}/.local || echo "Warning: failed setting +rx on ~/.local" >&2
    local item
    # Any shellkit tools should have a ~/.local/bin/*/shellkit/ dir, that's how we recognize them:
    for item in $(command ls -d ${HOME}/.local/bin/*/shellkit/); do
        (
            builtin cd $(command dirname -- ${item}) \
            && chmod og+rX . -R;
        )
    done
}

install_loader() {
    (
        cd ${HOME}/.local/bin || die 701
        for ff in shellkit-loader.{bashrc,sh}; do
            [[ -f ${Kitname}/shellkit/${ff} ]] || die "Kit ${Kitname} is missing ${ff}"
        done
        ourVersion=$( ${Kitname}/shellkit/shellkit-loader.sh --version )
        curVersion=$( ./shellkit-loader.sh --version 2>/dev/null || echo 0 )
        [[ $curVersion -gt $ourVersion ]] && {
            exit 0  # We won't overwrite a newer version
        }
        cp ${Kitname}/shellkit/shellkit-loader.{bashrc,sh} ./ || die

    ) || exit 1
}

main_base() {
    [[ -z $Script ]] && die "\$Script not defined in main_base()"
    ensure_HOME
    [[ $1 == --run-bashrc-hook ]] && {
        shift
        shrc_fixup "$@"
        exit
    }
    if [[ ! -d $HOME/.local/bin/${Kitname} ]]; then
        if [[ -e $HOME/.local/bin/${Kitname} ]]; then
            # Here we're protecting the kit maintainer: if they replace the ~/.local/bin/{kitname} dir
            # with a symlink, we're hands-off and won't overwrite the content.
            die "$HOME/.local/bin/${Kitname} exists but is not a directory.  Refusing to overwrite"
        fi
        command mkdir -p $HOME/.local/bin/${Kitname} || die "Failed creating $HOME/.local/bin/${Kitname}"
    fi
    if [[ $(inode $Script) -eq $(inode ${HOME}/.local/bin/${Kitname}/setup.sh) ]]; then
        # shellkit is designed to be re-installable from the original ~/.local/bin/ CONTENT,
        # but not from within the original LOCATION.  In other words, you can do a `cp -r ~/.local/bin/{kitname} /tmp/{kitname}`,
        # and then run setup.sh from /tmp/{kitname}.  That's OK, and setup will overwrite the original
        # stuff in ~/.local/bin.  But you can't just run setup.sh from ~/.local/bin/{kitname}.  This prevents
        # weird mistakes, but allows (for example) the kit to be mounted in a docker /host_home and installed
        # into the container
        die "cannot run setup.sh from ${HOME}/.local/bin"
    fi
    builtin cd ${HOME}/.local/bin/${Kitname} || die "101"
    command rm -rf ./* ./.* &>/dev/null
    [[ -d ${scriptDir} ]] || die "bad scriptDir [$scriptDir]"
    command cp -r ${scriptDir}/* ./ || die "failed copying from ${scriptDir} to $PWD"
    builtin cd .. # Now were in .local/bin
    command ln -sf ./${Kitname}/${Kitname}-version.sh ./ || die "102.2"
    path_fixup_local_bin ${Kitname} || die "102.5"
    install_realpath_sh || die "104.5"
    install_symlinks || die "105"
    install_loader || die "105.5"
    run_bashrc_hook || die "105.7"
    fixup_local_bin_perms || die "106"
    echo "${Kitname} installed in ~/.local/bin: OK"
    $reload_reqd && builtin echo "Shell reload required ('bash -l')" >&2
}

