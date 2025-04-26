#!/bin/bash

_whichcode () 
{ 
    [[ -e $VSCODE_IPC_HOOK_CLI ]] && { 
        local remoteCli_1;
        remoteCli_1=$(command ls ${HOME}/.vscode-remote/bin/*/bin/remote-cli/code 2> /dev/null | head -n 1);
        readonly remoteCli_1;
        [[ -x "${remoteCli_1}" ]] && { 
            echo "${remoteCli_1}" "$@";
            return
        };
        local remoteCli_2
        remoteCli_2="$(command which code 2> /dev/null)";
        readonly remoteCli_2;
        if [[ "${remoteCli_2}" == *server/cli*code ]]; then
            echo "${remoteCli_2}" "$@";
            return;
        fi;
        command which code-server &> /dev/null && { 
            echo command code-server "$@";
            return
        }
    };
    which code &> /dev/null && { 
        echo command code "$@";
        return
    };
    
    command vimdiff "$@"
}

_whichcode "$@"
