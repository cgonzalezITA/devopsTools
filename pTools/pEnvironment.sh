#!/bin/bash
#********************************************************************************
# DevopsTools
# Version: 1.0.0 
# Copyright (c) 2025 Instituto Tecnologico de Aragon (www.ita.es)
# Date: September 2025
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

# Creates the env for the project
ENVROOTFOLDER=/python/.envs # This is just a proposal, feel free to change it
ENVNAME=env_name
PYTHONCMD=$(which python) # This command may change depending on the python version installed on the host.

# \t-n <NamespaceClue>: Specifies a clue of the namespace to be used                                    \n
CREATE=false
ACTIVATE=false
DEACTIVATE=false
REQUIREMENTS_FILE=''
LIST=false
CUSTOM_ENVNAME=false
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] \n 
            \t-p | --pythoncmd <pythoncmd>: Python command to use (def. python or python3 if python not found) \n
            \t-rf | --rootfolder <rootfolder>: Root folder where the envs are stored (def. $ENVROOTFOLDER) \n
            \t-e | --envname <envname>: Name of the python env (def. $ENVNAME) \n
            \texport DEF_PTOOLS_ENVNAME=<env_name>: To avoid using -e param, you can set this env var before running the script \n              
            \t-c | --createenv: Creates python env (def.false)\n
            \t-a | --activate: Activates python env (def. false) \n
            \t-d | --deactivate: Deactivates python env \n
            \t-r | --requirements <requirementsfile>: Requirements file to install packages (def. none) \n
            \t-h | --help: Shows this help\n
            \t-l | --list: Lists available envs at ENVROOTFOLDER\n"
    echo $HELP
}

##############################
## Main code                ##
##############################

# getopts arguments
while true; do
    [[ "$#" -eq 0 ]] && break;
    case "$1" in
        -h | --help ) 
            echo -e $(help);
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            break ;;
        -l | --list )
            LIST=true; shift ;;
        # \t-c | --createenv: Creates python env (def.false)\n
        # \t-p | --pythoncmd: Python command to use (def. python or python3 if python not found) \n
        -p | --pythoncmd )
            if [[ "$#" -le 1 ]]; then echo "Error: Missing argument for -p|--pythoncmd option"; [ "$CALLMODE" == "executed" ] && exit -1 || return -1; fi
            PYTHONCMD=$2; shift 2 ;;
        -c | --createenv )
            CREATE=true; shift ;;
        # \t-a | --activate: Activates python env (def. true) \n
        -a | --activate )
            ACTIVATE=true; shift ;;
        # \t-d | --deactivate: Deactivates python env \n
        -d | --deactivate )
            DEACTIVATE=true; shift ;;
        # \t-e | --envname: Name of the python env (def. $ENVNAME) \n
        -e | --envname )
            if [[ "$#" -le 1 ]]; then echo "Error: Missing argument for -e | --envname option"; [ "$CALLMODE" == "executed" ] && exit -1 || return -1; fi
            ENVNAME=$2; 
            CUSTOM_ENVNAME=true;
            shift 2 ;;
        # \t-r | --requirements: Requirements file to install packages (def. none) \n
        -rf | --rootfolder )
            if [[ "$#" -le 1 ]]; then echo "Error: Missing argument for -rf | --rootfolder option"; [ "$CALLMODE" == "executed" ] && exit -1 || return -1; fi
            ENVROOTFOLDER=$2; shift 2 ;;
        -r | --requirements )
            if [[ "$#" -le 1 ]]; then echo "Error: Missing argument for -r | --requirements option"; [ "$CALLMODE" == "executed" ] && exit -1 || return -1; fi
            REQUIREMENTS_FILE=$2; 
            shift 2 ;;
        # catch all for unknown params or positional args
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
            else
                echo "Warning: Argument [$1] ignored";
            fi ;
            shift ;;
    esac
done

if [ -z "$PYTHONCMD" ]; then
    echo "WARNING: python is not installed or not in the PATH. Trying python3 instead..."
    PYTHONCMD=$(which python3)
    if [ -z "$PYTHONCMD" ]; then
        echo "ERROR: python not python3 are not installed or not in the PATH. Please install python before continuying using this script."
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
fi



echo "PYTHONCMD=[$PYTHONCMD]"
PVERSION=$($PYTHONCMD --version 2>&1 | awk '{print $2}')
echo "PVERSION=[$PVERSION]"

if [ "$CUSTOM_ENVNAME" = false ] && [ -n "$DEF_PTOOLS_ENVNAME" ]; then
    ENVNAME=$DEF_PTOOLS_ENVNAME
    echo "Using env name from DEF_PTOOLS_ENVNAME env var: '$ENVNAME'"
fi
echo "Working with python version: $PVERSION ($PYTHONCMD). Selected python env='$ENVNAME' in $ENVROOTFOLDER"

PYTHONENV=$ENVROOTFOLDER/$ENVNAME/bin  

if [ "$LIST" = true ]; then
    echo "Available envs in $ENVROOTFOLDER folder:"
    ls -1 "$ENVROOTFOLDER" | sed 's/^/- /'
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if [ "$CREATE" = true ]; then
    echo "Creating python env $ENVNAME int $ENVROOTFOLDER..."
    read -p "Press [ENTER] to continue or [CTRL+C] to abort"
    sudo mkdir -p  $ENVROOTFOLDER
    $PYTHONCMD -m venv --copies $ENVROOTFOLDER/$ENVNAME 
fi

if [ "$ACTIVATE" = true ]; then
    echo "Activating python env $PYTHONENV..."
    read -p "Press [ENTER] to continue or [CTRL+C] to abort"
    source $PYTHONENV/activate  
fi
if [ -n "$REQUIREMENTS_FILE" ]; then
    echo "Installing requirements from $REQUIREMENTS_FILE..."
    read -p "Press [ENTER] to continue or [CTRL+C] to abort"
    pip install --no-cache-dir -r $REQUIREMENTS_FILE
fi

if [ "$DEACTIVATE" = true ]; then
    echo "Deactivating python env $PYTHONENV..."
    deactivate
fi
