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

# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# \t-fv: Force secretname match the given clue (using this, the clue is not a clue, but the name)       \n
USECCLUE=true
# \t<docker name clue>: Clue to identify the artifact file name                                         \n
PODCLUE=""
# \t<command>: Command to be executed inside the pod"
COMMAND=""
ARTIFACT=ps
# \t-y: No confirmation questions are asked                                                             \n
ASK=true

#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <docker name clue> [<command:def: sh>]                         \n 
            \t-h: Show help info                                                                            \n
            \t-y: No confirmation questions are asked                                                             \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)      \n
            \t-v: Do not show verbose info                                                                  \n
            \t<componet name clue>: Clue to identify the running docker                                     \n
	    \t<command>: Command to be executed inside the pod (def rm)"
    echo $HELP
}


##############################
## Main code                ##
##############################

# getopts arguments
while true; do
    [[ "$#" -eq 0 ]] && break;
    case "$1" in
        -v | --verbose ) 
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            # echo "help rc=$?"
            if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
            break ;;
        -y | --yes ) 
            ASK=false; shift ;;
        -fv | --forcevalue ) 
            USECCLUE=false; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#PODCLUE}" -eq 0; then
                PODCLUE=$1
                shift;
            elif test "${#COMMAND}" -eq 0; then
                COMMAND=$1;
                shift;
            fi ;;
    esac
done

if test "${#PODCLUE}" -eq 0; then
    echo -e $(help "ERROR: <docker name clue> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif test "${#COMMAND}" -eq 0; then
    COMMAND="rm"
fi

# Code
getComponents_result=$( $BASEDIR/_dGetContainers.sh "$ARTIFACT" "$USECCLUE" "$PODCLUE" "delete" $ASK "" "Looking for components to remove");
RC=$?; 
if test "$RC" -ne 0; then 
    echo -e $(help "  ERROR: $getComponents_result");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif test "${#getComponents_result}" -eq 0; then
    # Selected not to use the artifacts
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
else    
    PODNAME=$getComponents_result;
fi

if [ "$VERBOSE" = true ]; then
    echo 
    echo "  DOCKERNAME=[$PODCLUE] -> [$PODNAME]"
    echo "  COMMAND=[$COMMAND]"
fi

if [ "$ASK" = true ]; then
    MSG="QUESTION: Really sure to delete container [$PODNAME]?"
    echo "---"
    read -p "$MSG. Should I go ahead [Y/n]? " -n 1 -r
    echo > /dev/tty;
else REPLY="y"; fi

if [[ $REPLY =~ ^[1Yy]$ ]]; then
    CMD="docker $COMMAND -f $PODNAME"
    echo INFO: Running COMMAND [$CMD]
    echo "---"
    bash -c "$CMD"
    RC=$?; 
    if test "$RC" -ne 0; then 
        echo "ERROR: Error running command [$COMMAND] (RC=$RC)"
    fi;
fi;
