#!/bin/bash
# shellkit-help.sh


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
    ( builtin cd -L -- "$(command dirname -- "$0")" || exit; builtin echo "$(command pwd -P)/$(command basename -- "$0")" )
}

scriptName="${scriptName:-"$(canonpath "$0")"}"
scriptDir=$(command dirname -- "${scriptName}")
scriptBase=$(command basename -- "${scriptName}")

die() {
    builtin echo "ERROR(${scriptBase}): $*" >&2
    builtin exit 1
}

stub() {
    # Print debug output to stderr.  Call like this:
    #   stub ${FUNCNAME[0]}.$LINENO item item item
    #
    builtin echo -n "  <<< STUB" >&2
    for arg in "$@"; do
        echo -n "[${arg}] " >&2
    done
    echo " >>> " >&2
}

# Defines bpoint():
_DEBUG_=${_DEBUG_:-0}
if [[ $_DEBUG_ -eq 1 ]]; then
    echo "_DEBUG_ enabled, sourceMeRun.taskrc is loading." >&2
    #shellcheck disable=1090
    [[ -f ~/bin/sourceMeRun.taskrc ]] && source ~/bin/sourceMeRun.taskrc
else
    bpoint() { : ;} # no-op
fi


parse_help_items() {
    # Given a stream of shell text with #help markers, print a "help item" for
    # each.
    while read -r line; do
        echo -n "$line" | tr -d '(){' | sed -e 's/^function //'
        read -r helptext
        #shellcheck disable=2001
        echo "$helptext" | sed 's/^\s*#help/\t/'
        read -r _
    done < <(command grep -E -B1 '\s*#help ')

}

parse_help_from_scripts() {
    # Each arg is a file, potentially with help items
    for arg; do
        [[ -f ${arg} ]] && {
            parse_help_items <"$arg"
        }
    done
}

parse_help_from_symlinks_() {
    # When:
    #    ${Kitname} is defined
    #    $./_symlinks_ exists
    # Then:
    #   - Read help specs from comments after each symlink name
    #   - Match instruction patterns:
    #      <symlink-name> #help <help text>
    #         (print <help text>)
    #      <symlink-name> #help@ <command text>
    #         (Run  command after #help@.  CWD is ~/.local/bin and <symlink-name>
    #          is $SHELLKIT_HELP_SYMBOL).  A typical command would output info
    #          to stdout, e.g.:
    #             git-foo-stuff #help@ $SHELLKIT_HELP_SYMBOL --help
    #
    [[ -f ./_symlinks_ ]] || return
    [[ -n "${Kitname}" ]] || return
    while read -r SHELLKIT_HELP_SYMBOL parsekey text; do
        case "$parsekey" in
            '#help@')
                export SHELLKIT_HELP_SYMBOL
                echo "${SHELLKIT_HELP_SYMBOL}:"
                (
                    cd ~/.local/bin || exit
                    eval "${text}"
                ) 2>&1 | command fold -s | command sed 's/^/   /'
                ;;
            '#help')
                echo -e "${SHELLKIT_HELP_SYMBOL}\t${text}"
                ;;
        esac
    done < ./_symlinks_
}

set_kitname() {
    # When:
    #   $scriptDir is set and is a child of the kit's working tree
    #   Kitname exists for current dir or parent
    # Then:
    #   Set $Kitname from ./Kitname contents
    local _f=${FUNCNAME[0]}
    [[ -d $scriptDir ]] || return
    Kitname=$(
        cd "$scriptDir" || die "$_f.1"
        xdir=$scriptDir
        for _ in {1..3}; do
            [[ -f ${xdir}/Kitname ]] && {
                command cat "${xdir}/Kitname"
                exit
            }
            xdir=$(dirname "$xdir")
        done
        false
    )
    [[ -n $Kitname ]] || die "$_f.2"
}

main() {
    [[ -n $Kitname ]] || set_kitname || die "Failed to set kitname in ${FUNCNAME[0]}.$LINENO"
    parse_help_from_scripts "$@"
    [[ -f ~/.local/bin/${Kitname}/_symlinks_ ]] && {
        (
            cd ~/.local/bin/"${Kitname}" || exit
            Kitname=${Kitname} parse_help_from_symlinks_
        )
    }
}

[[ -z ${sourceMe} ]] && main "$@"

