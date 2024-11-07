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

#############################
## Functions               ##
#############################
function help() {
    HELP="HELP: USAGE: $SCRIPTNAME [-h] [-s <submodulePath>] <comment1 (with quotes \")> [<comment2 (with quotes \")>]"
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
            fi
            break ;;
    esac
done

if test "$#" -lt 1; then
    echo -e $(help "ERROR: <comment1 (with quotes \")> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
C1=$1
C="-m \"$C1\""
shift;
C2=""
if test "$#" -ge 1; then
    C2=$1    
    C="$C -m \"${C2}\""
fi

CMD="git commit $C"
echo -e "---\n  Running git commit command at [$(pwd)] folder..."
if [ "$VERBOSE" = true ]; then
    echo "  >     SUBMODULE= [$SUBMODULE]"
    echo "  >          PATH= $( pwd )"
    echo "  >            C1= [$C1]"
    echo "  >            C2= [$C2]"
    echo "  >Running command [$CMD]"
fi
echo "---"
echo "  DO NOT FORGET TO ADD THE FILES TO COMMIT BEFORE PROCEEDING"
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
