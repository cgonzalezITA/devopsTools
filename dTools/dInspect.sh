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
# \t<artifact>: Artifact to be described (ps*|network|volumes|...)                                     "
ARTIFACT="ps"
ARTIFACTLS=""
ARTIFACT_FORMATNAMES="{{.Names}}"
ARTIFACT_FORMATIDS="{{.ID}}"

ARTIFACTS="ps network secret"
ARTIFACTSFULLNAMES=" all ps network networks secret secrets "
#############################
## Functions               ##
#############################
function help() {
    HELP="HELP: USAGE: $SCRIPTNAME [optArgs] <docker name clue> <artifact>                                            \n 
            \t-h: Show help info                                                                            \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)      \n
            \t-v: Do not show verbose info                                                                  \n
            \t<componet name clue>: Clue to identify the running docker                                     \n
            \t<artifact>: Artifact to be described (ps*|network|volumes|...)                                "    
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
            if [[ $1 == -* && $1 != --* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#PODCLUE}" -eq 0; then
                PODCLUE=$1
            elif test "${#ARTIFACT}" -eq 0; then
                ARTIFACT=$1;
            fi
            shift;;
    esac
done

if test "${#PODCLUE}" -eq 0; then
    echo -e $(help "ERROR: <docker name clue> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi



if [[ ! ${ARTIFACTSFULLNAMES[@]} =~ " $ARTIFACT " ]]
then
    TMP=$PODCLUE
    PODCLUE=$ARTIFACT
    ARTIFACT=$TMP
fi

if test "$ARTIFACT" == "ps"; then
    ARTIFACTLS=""
    ARTIFACT_FORMATNAMES="{{.Names}}"
    ARTIFACT_FORMATIDS="{{.ID}}"
else
    ARTIFACTLS="ls"
    ARTIFACT_FORMATNAMES="{{.Name}}"
    if test "$ARTIFACT" == "volume"; then
        ARTIFACT_FORMATIDS="{{.Name}}"
    else
        ARTIFACT_FORMATIDS="{{.ID}}"
    fi
fi

# Code
getComponents_result=$( $BASEDIR/_dGetContainers.sh "$ARTIFACT" "$USECCLUE" "$PODCLUE" "Inspect" false "" "Looking for components to inspect");
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
#     PODNAME=$(docker $ARTIFACT $ARTIFACTLS --format \'$ARTIFACT_FORMATNAMES\'| tac | grep $PODCLUE)
#     if test "${#PODNAME}" -eq 0; then
#         PODNAME=$(docker $ARTIFACT $ARTIFACTLS --format \'$ARTIFACT_FORMATIDS\'| tac | grep $PODCLUE)
#     fi
#     PODNAMEDESC=$(docker $ARTIFACT $ARTIFACTLS --format \'$ARTIFACT_FORMATIDS:$ARTIFACT_FORMATNAMES\'| tac | grep $PODCLUE)
# else
#     PODNAME=$PODCLUE
#     PODNAMEDESC=$PODCLUE
# fi

if [ "$VERBOSE" = true ]; then
    echo "  [$ARTIFACT] NAME=[$PODCLUE] -> [$PODNAME]"
    echo "  ARTIFACT=[$ARTIFACT]"
fi

echo "INFO: Getting description of [$ARTIFACT] [$PODCLUE]"
echo "---"
PODNAME=${PODNAME%\'}
PODNAME=${PODNAME#\'}
if test "$ARTIFACT" == "ps"; then
    ARTIFACT=""
fi
docker $ARTIFACT inspect $PODNAME