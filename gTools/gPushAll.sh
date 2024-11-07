#!/bin/bash
#********************************************************************************
# DevopsTools
# Version: 1.0.0 
# Copyright (c) 2024 Instituto Tecnologico de Aragon (www.ita.es)
# Date: October 2024
# Authors: 
#          Carlos Gonzalez Muñoz                    cgonzalez@ita.es
# All rights reserved 
#********************************************************************************
############################
## Variable Initialization #
############################
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")

#############################
## Functions               ##
#############################
function help() {
    HELP="HELP: USAGE: $SCRIPTNAME # Pushes all commits from the current git and its submodules                      \n
            \t-h: Show help info                                                                                     \n
            \t---                                                                                                    \n
            \tThis tool needs a previous setup.                                                                      \n
            \tThe following lines have to be added to the ~/.gitconfig file to enable the git command 'git push-all' \n
            \t[alias]                                                                                                \n
            \tpush-all = \"! find . -depth -name .git -exec dirname {} \\\\\\; 2> /dev/null | sort -n -r | xargs -I{} bash -c \\\"cd {}; git status | grep ahead > /dev/null && { echo '**** Pushing: {} ****'; git push; }\\\\\"\""
    if test "$#" -ge 1; then
        HELP="${HELP}\n${1}"     
    fi
    echo $HELP
}


##############################
## Main code                ##
##############################

# getopts arguments
while true; do
    case "$1" in
        -h | --help ) 
            echo -e $(help);
            # echo "help rc=$?"
            if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
            break ;;
        * )  
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            fi
            break ;;
    esac
done

echo -e "Pushing pending commits of current git and its submodules...\n---"

git push-all
# RC=$?
# if test "$RC" -ne 0; then 
#     echo "Process finished with Return Code $RC"
# fi