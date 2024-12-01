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

#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <docker name clue> [<command:def: sh>]                         \n 
            \t-h: Show help info                                                                            \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)      \n
            \t-v: Do not show verbose info                                                                  \n
            \t<componet name clue>: Clue to identify the running docker                                     \n
	    \t<command>: Command to be executed inside the pod (def /bin/bash)"
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
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            break ;;
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
    COMMAND="/bin/bash"
fi

# Code
getComponents_result=$( $BASEDIR/_dGetContainers.sh ps "$USECCLUE" "$PODCLUE" "Run command $COMMAND" false "" "Looking for container to run into");
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
    echo "  DOCKERNAME=[$PODCLUE] -> [$PODNAME]" | egrep --color=auto  "$PODCLUE"
    echo "  COMMAND=[$COMMAND]"
fi
# if test "${#PODNAME}" -eq 0; then
#     echo -e $(help "ERROR: No docker with name or id clue [$PODCLUE] has been found");
# else
#     NLINES=$(echo "$PODNAME" | wc -l)
#     if test "$NLINES" -ne 1; then
#         echo -e $(help "ERROR: Docker clue [$PODCLUE] is too generic. [$NLINES] matches have been found: [$PODNAME]")
#         echo -e "dockers similar to [$PODCLUE]:\n$(docker ps --format '{{.ID}}: {{.Names}}'| tac | grep $PODCLUE)"
#         [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
#     fi
# fi
echo INFO: EXECUTING COMMAND [$COMMAND] inside [$PODNAME]
echo "---"
CMD="docker exec -it $PODNAME \"$COMMAND\""
echo "  Running command [${CMD}]" | egrep --color=auto  "$PODCLUE"
echo "---"
bash -c "$CMD"
RC=$?; 
if test "$RC" -eq 126; then 
    if [[ "$COMMAND" =~ (bash)$ ]]; then
        echo "---"
        MSG="ERROR: Error running command [$COMMAND] (RC=$RC)"
        COMMAND="/bin/sh"
        read -p "$MSG. Do you want to try [$COMMAND] instead? ('y/n')" -n 1 -r
        echo "";
        if [[ $REPLY =~ ^[Y|y]$ ]]; then 
            CMD="docker exec -it $PODNAME \"$COMMAND\""
            echo "  Running command [${CMD}]" | egrep --color=auto  "$PODCLUE"
            echo "---"
            bash -c "$CMD"
        fi
    else
        echo "ERROR: Error running command [$COMMAND] (RC=$RC)"
    fi
fi;
