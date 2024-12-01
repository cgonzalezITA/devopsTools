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

# \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# FOLDER_ARTIFACTS=./KArtifacts/
COMMAND=get
ARTIFACT=ps
CCLUE=""
# \t-fs: Force secretname match the given clue (using this, the clue is not a clue, but the name)       \n
USECCLUE=true
ARTIFACTS="ps network secret"
ARTIFACTSFULLNAMES=" all ps network networks secret secrets "
# \t-p: Show components of project (These components were created by a docker-component cmd with a project)  \n
PROJECTNAME=""
#############################
## Functions               ##
#############################
function help() {
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="HELP: USAGE: $SCRIPTNAME [optArgs] [<component clue>] \n 
            \t-h: Show help info                                                                                       \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)                 \n
            \t-v: Do not show verbose info                                                                             \n
            \t-p: Show components of project (These components were created by a docker-component cmd with a project)  \n
            \t[<component clue>]: Clue to identify the artifact file name|all                                          \n
            \t[<docker artifact>]: docker Artifact to show info about. Values: ps*, all, network, ...                  \n
            \n[<component clue>] and [<docker artifact>] can in some context be swapped to match existing artifacts"
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
        -v) 
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            break ;;
        -fv|--forcevalue) 
            USECCLUE=false; shift ;;
        -p | --projectname ) 
            PROJECTNAME=$2
            shift; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            fi
            break ;;
    esac
done

PROVIDEDPARAMS=$#
if test "$#" -ge 1; then
    ARTIFACT=$1; shift;
fi
if test "$#" -lt 1; then
    USECCLUE=false
    CCLUE="all"
else
    CCLUE=$1
    shift;
fi
if [[ ! ${ARTIFACTSFULLNAMES[@]} =~ " $ARTIFACT " ]]
then
# echo "Artifact value not found: $PROVIDEDPARAMS"
# Swapping is done between ARTIFACT AND CCLUE
    if test "$PROVIDEDPARAMS" -le 1; then
        CCLUE=$ARTIFACT
        ARTIFACT=ps
    elif test "$PROVIDEDPARAMS" -le 2; then
        TMP=$CCLUE
        CCLUE=$ARTIFACT
        ARTIFACT=$TMP
    fi
fi

if  [ "$ARTIFACT" == "all" ]; then
    # Gets all k8s artifacts. As shown in https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
    echo "---"
    echo "Gets artifacts matching the clue [$CCLUE]..."
    for artifact in $ARTIFACTS; do
        item=$CCLUE

        echo "---"
        read -p "  Getting [$artifact] $item: (press a key to continue)" -n 1 -r
        echo "";
        $SCRIPTNAME -fv $artifact $item 
    done
    echo ""
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
if  [ "$CCLUE" == "all" ]; then
    GREPCMD=""
    PATTERNDESC=""
else
    GREPCMD="| grep $CCLUE | egrep --color=auto  '$CCLUE|$'"
    PATTERNDESC="[*$CCLUE*]"
fi

if  [ "$ARTIFACT" != "ps" ]; then
    POSTCOMMAND=ls
else
    POSTCOMMAND="-a"
fi

if [ "$VERBOSE" = true ]; then
    # echo "  ARTIFACTS_FOLDER=[$FOLDER_ARTIFACTS]"
    # echo "  K8S_COMPONENTNAME=[$CCLUE] -> [$GREPCMD]"
    echo "  CCLUE=$CCLUE"
    echo "  ARTIFACT=[$ARTIFACT]"
    echo "  COMMAND=[$COMMAND]"
    echo "  PROJECTNAME=[$PROJECTNAME]"
fi
echo "  INFO: Getting [$ARTIFACT] $PATTERNDESC"

if test "${#PROJECTNAME}" -gt 0; then 
    PROJECTNAME="--filter label=com.docker.compose.project=$PROJECTNAME"
fi
CMD="docker $ARTIFACT $POSTCOMMAND $PROJECTNAME $GREPCMD"
echo "  Running command [${CMD}]"
echo "---"
bash -c "$CMD"