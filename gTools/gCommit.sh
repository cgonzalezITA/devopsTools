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
FOLDER_VALUES=./HValues
VERBOSE=true
SUBMODULE=""
PWD1=$(pwd)
C1=""
C2=""
# \t-y: No confirmation questions are asked                                                             \n
ASK=true
# \t[-t|--tag] TAG: Adds a tag to commit \n
TAG=""
# \t[-tc|--tagComment] TAGCOMMENT: Adds a comment to the tag\n"
TAGC=""

#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [-h] [-s <submodulePath>] <comment1 (with quotes \")> [<comment2 (with quotes \")>] [-t TAG] [-tc TAGCOMMENT] \n 
            \t-h: Show help info \n
            \t-y: No confirmation questions are asked \n
            \t[-t|--tag] TAG: Adds a tag to commit \n
            \t[-tc|--tagComment] TAGCOMMENT: Adds a comment to the tag\n"
    echo $HELP
    HELP="HELP: USAGE: $SCRIPTNAME "
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
             [ "$CALLMODE" == "executed" ] && exit -1 || return -1; ;;
        -a | --ask ) 
            VERBOSE=false; shift ;;
        -t | --tag ) 
            TAG=$2; shift; shift ;;
        -tc | --tagComment ) 
            TAGC=$2; shift; shift ;;
        -s | --submodule | -f | -m ) 
            SUBMODULE=$2
            if ! test -d $SUBMODULE; then 
                echo -e $(help "ERROR: Submodule folder [$SUBMODULE] must exist"); 
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
             fi
            shift ; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#C1}" -eq 0; then
                C1=$1;
                C="-m \"$C1\""
            elif test "${#C2}" -eq 0; then
                C2=$1;
                C="$C -m \"${C2}\""
            fi
            shift ;;
    esac
done

if test "${#C1}" -eq 0; then
    echo -e $(help "ERROR: <comment1 (with quotes \")> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if [ "$VERBOSE" = true ]; then
    echo " PATH= $( pwd )"
    echo " SUBMODULE= [$SUBMODULE]"
    echo " C1= [$C1]"
    echo " C2= [$C2]"
    echo " TAG= [$TAG]"
    echo " TAGCOMMENT=[$TAGC]"
fi
CMD="git commit $C"
if test "${#TAG}" -gt 0; then
    CMD="$CMD; git tag -a \"$TAG\" -m \"$TAGC\""
fi
if [ "$VERBOSE" = true ]; then
    echo "  >Running command [$CMD]"
    echo "---"
fi
read -p "  Are you sure to run the command [Y/n]? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    if test "${#SUBMODULE}" -gt 0; then
        cd $SUBMODULE;
    fi
    echo ---
    bash -c "$CMD"
    cd $PWD1
fi
