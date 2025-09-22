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

COMMAND="show"
SUBCOMMAND=""
SUBCOMMANDS=" chart crds readme values all "
# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# \t-f <folder with helm config>: Folder where the config file must be located (def value: ./HValues    \n
FOLDER_VALUES=./Helms
# \t-fv: Force secretname match the given clue (using this, the clue is not a clue, but the name)       \n
HCLUE=""
USECCLUE=true
# EXTRACOMPONENTS=""
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n---"     
    else
        HELP=""
    fi
    HELP="$HELP\nUSAGE: $SCRIPTNAME [optArgs] <component clue> [<subcommand>]                                     \n 
            \t-h: Show help info                                                                                  \n
            \t-v: Do not show verbose info                                                                        \n
            \t-f <folder with helm stuff>: Base folder where the helms are located (def value: ./Helms)           \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)            \n
            \t<component clue>: Clue to identify the artifact file name.                                          \n
            \t<subcommand>: def. chart. Values: [$SUBCOMMANDS]"
    echo $HELP
}


##############################
## Main code                ##
##############################

while true; do
    [[ "$#" -eq 0 ]] && break;
    case "$1" in
        -v ) 
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            # echo "help rc=$?"
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
            break ;;
        -fv | --forcevalue ) 
            USECCLUE=false; shift ;;
        -f ) 
            FOLDER_VALUES=$2
            if ! test -d $FOLDER_VALUES;then 
                echo -e $(help "ERROR: Folder [$FOLDER_VALUES] must exist");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
            fi
            shift ; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
            elif test "${#HCLUE}" -eq 0; then
                HCLUE=$1
                CCLUEORIG=$1
            elif test "${#SUBCOMMAND}" -eq 0; then
                SUBCOMMAND=$1;
            fi ;
            shift ;;
    esac
done

if test "${#HCLUE}" -eq 0; then
    echo -e $(help "# ERROR: <component clue> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
elif test "${#SUBCOMMAND}" -eq 0; then
    SUBCOMMAND="chart"
fi

if [[ ! ${SUBCOMMANDS[@]} =~ " $SUBCOMMAND " ]]
then
    # Swaps HCLUE AND SUBCOMMAND
    TMP=$HCLUE
    HCLUE=$SUBCOMMAND
    CCLUEORIG=$SUBCOMMAND
    SUBCOMMAND=$TMP
fi


if [ "$USECCLUE" = true ]; then
    shopt -s expand_aliases
    . ~/.bash_aliases
    # Search a file named config.* in a folder alike "$HCLUE"
    getFileResult=$(_fGetFile "$FOLDER_VALUES" "$USECCLUE" "$HCLUE" "$HCLUE" false true);
    # echo "getFileResult=$getFileResult"
    RC=$?; 
    if test "$RC" -ne 0; then 
        echo -e $(help "  ERROR: $getFileResult");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    elif test "${#getFileResult}" -eq 0; then
        # Selected not to use the artifacts
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    else           
        HFOLDER=$getFileResult;
        # echo "FCONFIGFOLDER=$FCONFIGFOLDER"
    fi
else
    HFOLDER=$HCLUE
fi
FCONFIGFOLDER="$(dirname "${HFOLDER}")"

if [ "$VERBOSE" = true ]; then
    echo -e "# -BASE_FOLDER=[$FOLDER_VALUES]    " 
    echo -e "# -HFOLDER=[$HCLUE] -> [$HFOLDER] " | egrep --color=auto  "$CCLUEORIG"
    echo -e "# -COMMAND=[$COMMAND]                 " 
    echo -e "# -SUBCOMMAND=[$SUBCOMMAND]" | egrep --color=auto  "$SUBCOMMAND"
fi

CMD="helm $COMMAND $SUBCOMMAND $HFOLDER 2>&1"
echo -e "# Running command [$CMD]\n---"
bash -c "$CMD"
echo "---"
