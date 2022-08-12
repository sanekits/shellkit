#!/bin/bash
# shellkit-help.sh

canonpath() {
    # Like "readlink -f", but portable
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}

scriptName="$(canonpath $0)"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

parse_help_items() {
    # Given a stream of shell text with #help markers, print a "help item" for
    # each.
    while read line; do
        echo -n $line | tr -d '(){' | sed -e 's/^function //'
        read helptext
        echo "$helptext" | sed -s 's/^\s*#help/\t/'
        read _
    done < <(command grep -E -B1 '\s*#help ')

}

parse_help_from_scripts() {
    # Each arg is a file, potentially with help items
    for arg; do
        [[ -f ${arg} ]] && {
            cat ${arg} | parse_help_items
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
    while read SHELLKIT_HELP_SYMBOL parsekey text; do
        case "$parsekey" in
            '#help@')
                export SHELLKIT_HELP_SYMBOL
                echo "${SHELLKIT_HELP_SYMBOL}:"
                (
                    cd ~/.local/bin
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
    [[ -d $scriptDir ]] || return
    [[ -f ${scriptDir}/Kitname ]] && { read Kitname < ${scriptDir}/Kitname; return; }
    [[ -f ${scriptDir}/../Kitname ]] && { read Kitname < ${scriptDir}/../Kitname; return; }
    false
}

main() {
    set_kitname
    parse_help_from_scripts "$@"
    [[ -f ~/.local/bin/${Kitname}/_symlinks_ ]] && {
        (
            cd ~/.local/bin/${Kitname}
            Kitname=${Kitname} parse_help_from_symlinks_
        )
    }
}

[[ -z ${sourceMe} ]] && main "$@"

