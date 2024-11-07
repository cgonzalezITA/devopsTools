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
# \t<k8s componet name clue>: Clue to identify the artifact file name                                   \n
PODCLUE=""
# \t<command>: Command to be executed inside the pod"
COMMAND=/bin/bash
# \t-s <sinceTime>: Show logs generated since <sinceTime> moment. eg: 0s, 5s, 5m, 1h, ...               \n
SINCEARG=""
# \t-x \"<jsonArrayWithStrings2Exclude>\": Exclude lines containing any of the given strings            \n
GREPEXCLUDE=""
# \t-w: wait (3 seconds wait before running the command)                                                \n
DOWAIT=false

#############################
## Functions               ##
#############################
function help() {
    HELP="HELP: USAGE: $SCRIPTNAME [optArgs] <k8s componet name clue> [<command:def: sh>]                         \n 
            \t-h: Show help info                                                                                  \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)            \n
            \t-w: wait (3 seconds wait before running the command)                                                \n
            \t-v: Do not show verbose info                                                                        \n
            \t-x \"<jsonArrayWithStrings2Exclude>\": Exclude lines containing any of the given strings. Format: ["str1","str2",...] \n
            \t-s <sinceTime>: Show logs generated since <sinceTime> moment. eg: 0s, 5s, 5m, 1h, ...               \n
            \t<componet name clue>: Clue to identify the running docker                                           "
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
        -v | --verbose ) 
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
            break ;;
        -fv | --forcevalue ) 
            USECCLUE=false; shift ;;
        -s | --since ) 
            SINCEARG="--since $2"
            shift ; shift ;;
        -w | --wait ) 
            DOWAIT=true; shift ;;
        -x | --exclude )
            JSON2EXCLUDE=$2
            readarray -t GREPEXCLUDE   < <(echo $JSON2EXCLUDE | jq --raw-output 'map(sub("^";"| grep -v \"")) | map(sub("$";"\"")) | join(" ")')
            shift ; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            fi
            break ;;
    esac
done

# positional arguments
if test "$#" -lt 1; then
    echo -e $(help "ERROR: <k8s componet name clue> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
PODCLUE=$1
shift

if test "$#" -ge 1; then
    COMMAND=$1
fi

# Code
getComponents_result=$( $BASEDIR/_dGetContainers.sh ps "$USECCLUE" "$PODCLUE" "Show logs" false "" "Looking for components to see its logs");
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

# if [ "$USECCLUE" = true ]; then
#     PODNAME=$(docker ps --format '{{.Names}}'| tac | grep $PODCLUE)
#     if test "${#PODNAME}" -eq 0; then
#         PODNAME=$(docker ps --format '{{.ID}}'| tac | grep $PODCLUE)
#     fi
# else
#     PODNAME=$PODCLUE
# fi

echo "INFO: Showing logs of docker [$PODNAME]"
if [ "$VERBOSE" = true ]; then
    echo "  DOCKERNAME=[$PODCLUE] -> [$PODNAME]"
    echo "  SINCE=[${SINCEARG}]"
    echo "  STRING2EXCLUDE=$JSON2EXCLUDE"
fi
if test "${#PODNAME}" -eq 0; then
    echo -e $(help "ERROR: No docker with name or id clue [$PODCLUE] has been found");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
NLINES=$(echo "$PODNAME" | wc -l)
if test "$NLINES" -ne 1; then
    echo -e $(help "ERROR: Docker clue [$PODCLUE] is too generic. [$NLINES] matches have been found: [$PODNAME]")
    echo -e "dockers with names similar to $PODCLUE:\n $(docker ps --format '{{.Names}}'| tac | grep $PODCLUE)"
    echo -e "dockers with ids similar to $PODCLUE:\n $(docker ps --format '{{.ID}}'| tac | grep $PODCLUE)"
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

echo "---"
function run() {
    CMD="docker logs $SINCEARG -f $PODNAME"
    CMD=${CMD}${GREPEXCLUDE}
    MSG="  Running command [${CMD}]"
    if [ "$DOWAIT" = true ]; then
        MSG="$MSG\n    in 3 seconds (or press any key to continue)\n---"
        echo -e $MSG
        read -t 3 -p ""
    else
        echo -e $MSG
    fi
    bash -c "$CMD"
}
run