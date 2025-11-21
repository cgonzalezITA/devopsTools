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
ARTIFACT=""
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
    HELP="HELP: USAGE: $SCRIPTNAME [optArgs] [<docker artifact>] [<component clue>] \n 
            \t-h: Show help info                                                                                       \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)                 \n
            \t-v: Do not show verbose info                                                                             \n
            \t-p: Show components of project (These components were created by a docker-component cmd with a project)  \n
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
    [[ "$#" -eq 0 ]] && break;
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
            elif test "${#ARTIFACT}" -eq 0; then
                ARTIFACT=$1;
            elif test "${#CCLUE}" -eq 0; then
                CCLUE=$1;
            fi ;
            shift ;;
    esac
done

PROVIDEDPARAMS=$#
if test "${#ARTIFACT}" -eq 0; then
    ARTIFACT=ps;
fi

# echo "Artifact selected: [$ARTIFACT]"

if [[ ! ${ARTIFACTSFULLNAMES[@]} =~ " $ARTIFACT " ]]
then
# echo "Artifact $ARTIFACT not found: $ARTIFACTSFULLNAMES"
# Swapping is done between ARTIFACT AND CCLUE
    TMP=$CCLUE
    CCLUE=$ARTIFACT
    ARTIFACT=$TMP
    if test "${#ARTIFACT}" -eq 0; then
        ARTIFACT=ps;
    fi
    if [[ ! ${ARTIFACTSFULLNAMES[@]} =~ " $ARTIFACT " ]]
    then
        TMP=$CCLUE
        CCLUE=$ARTIFACT
        ARTIFACT=$TMP
        echo -e $(help "ERROR: Unknown artifact [$ARTIFACT]");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
fi
if  [ "$ARTIFACT" == "all" ]; then
    # Gets all k8s artifacts. As shown in https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
    echo "---" > /dev/tty;
    echo "Gets artifacts matching the clue [$CCLUE]..." > /dev/tty;
    for artifact in $ARTIFACTS; do
        item=$CCLUE

        echo "---"> /dev/tty;
        read -p "  Getting [$artifact] $item: (press a key to continue)" -n 1 -r
        echo "";
        $SCRIPTNAME -fv $artifact $item 
    done
    echo ""
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
if test "${#CCLUE}" -eq 0; then
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