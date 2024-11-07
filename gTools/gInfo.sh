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
VERBOSE=true
SUBMODULE=""
PWD1=$(pwd)

#############################
## Functions               ##
#############################
function help() {
    HELP="HELP: USAGE: $SCRIPTNAME [-h] [-s <submodulePath>]"
    if test "$#" -ge 1; then
        HELP="${HELP}\n${1}"     
    fi
    echo $HELP
    return $#;
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
             [ "$CALLMODE" == "executed" ] && exit -1 || return -1; ;;
        -s | --submodule | -f ) 
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
            fi
            break ;;
    esac
done

echo -e "---\n  Running [$CMD] command at [$(pwd)] folder..."
if [ "$VERBOSE" = true ]; then
    echo "  >     SUBMODULE= [$SUBMODULE]"
    echo "  >          PATH= $( pwd )"
fi

if test "${#SUBMODULE}" -gt 0; then
    cd $SUBMODULE;
fi

CMD="git rev-parse --show-toplevel"
echo -e ">Running command [$CMD]" 
GITROOTFOLDER=$($CMD)
echo "---"
LABEL="Git Root folder"
echo "- $LABEL: $GITROOTFOLDER" | egrep --color=auto  "$LABEL" 


CMD="git remote -v"
echo -e ">Running command [$CMD]"
echo "---"
LABEL="Remote Origin"
echo "- $LABEL:" | egrep --color=auto  "$LABEL" 
eval "$CMD"

CMD="git rev-parse --abbrev-ref HEAD"
echo "---"
echo -e ">Running command [$CMD]"
LABEL="Current Branch"
echo "- $LABEL:" $($CMD) | egrep --color=auto  "$LABEL" 

# CMD="git config --file .gitmodules --get-regexp path "
CMD="git submodule foreach --recursive git remote get-url origin"
echo "---"
echo -e ">Running command [$CMD]"
LABEL="Submodules"
echo "- $LABEL:" | egrep --color=auto  "$LABEL" 
cd $GITROOTFOLDER
LABEL="Module"
$CMD | sed "s|Entering|  ${LABEL}:|g"  | sed "s/\($LABEL\)/\x1b[31m\1\x1b[0m/g"


cd $PWD1