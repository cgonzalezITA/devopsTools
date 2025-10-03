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
PACKAGEMANAGER=pip
SHOWHELP=false
# Creates the env for the project
ENVROOTFOLDER=/python/.envs # This is just a proposal, feel free to change it
ENVNAME=env_name
PYTHONCMD=$(which python) # This command may change depending on the python version installed on the host.

# \t-n <NamespaceClue>: Specifies a clue of the namespace to be used                                    \n
CREATE=false
ACTIVATE=false
DEACTIVATE=false
REQUIREMENTS_FILE=''
LISTENVS=false
CUSTOM_ENVNAME=false
# \t-x | --export: Exports the list of installed packages\n
EXPORT_REQUIREMENTS=false
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] \n 
            \t[-p | --pythoncmd] <pythoncmd>: Python command to use (def. python or python3 if python not found) \n
            \t[-pm | --packageManager] <packageManager>: Python's package manager (def. pip). Values [pip|conda]\n
            \texport DEF_PTOOLS_PACKAGEMANAGER=<packageManager>: To avoid using -pm param, you can set this env var before running the script \n              
            \t[-rf | --rootfolder] <rootfolder>: Root folder where the envs are stored (def. $ENVROOTFOLDER) \n
            \t[-e | --envname] <envname>: Name of the python env (def. $ENVNAME) \n
            \texport DEF_PTOOLS_ENVNAME=<env_name>: To avoid using -e param, you can set this env var before running the script \n              
            \t[-c | --createenv]: Creates an empty python env (def.false)\n
            \t[-x | --export]: Exports the list of installed packages\n
            \t[-a | --activate]: Activates python env (def. false) \n
            \t[-d | --deactivate]: Deactivates python env \n
            \t[-ir | --installrequirements] <requirementsfile>: Requirements file to install packages (def. none) \n
            \t[-h | --help]: Shows this help\n
            \t[-lenvs | --listenvs]: Lists available envs at ENVROOTFOLDER\n"
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
        
            SHOWHELP=true;
            break ;;
        -lenvs | --listenvs )
            LISTENVS=true; shift ;;
        # \t-pm | --packageManager: Python's package manager (def. pip). Values [pip|conda] \n
        -pm | --packageManager )
            if [[ "$#" -le 1 ]]; then echo "Error: Missing argument for -pm|--packageManager option"; [ "$CALLMODE" == "executed" ] && exit -1 || return -1; fi
            PACKAGEMANAGER=$2; shift 2 ;;
        # \t-p | --pythoncmd: Python command to use (def. python or python3 if python not found) \n
        -p | --pythoncmd )
            if [[ "$#" -le 1 ]]; then echo "Error: Missing argument for -p|--pythoncmd option"; [ "$CALLMODE" == "executed" ] && exit -1 || return -1; fi
            PYTHONCMD=$2; shift 2 ;;
        # \t-c | --createenv: Creates python env (def.false)\n
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
        -rf | --rootfolder )
            if [[ "$#" -le 1 ]]; then echo "Error: Missing argument for -rf | --rootfolder option"; [ "$CALLMODE" == "executed" ] && exit -1 || return -1; fi
            ENVROOTFOLDER=$2; shift 2 ;;
        # \t-ir | --installrequirements: Requirements file to install packages (def. none) \n
        -ir | --installrequirements )
            if [[ "$#" -le 1 ]]; then echo "Error: Missing argument for -ir | --installrequirements option"; [ "$CALLMODE" == "executed" ] && exit -1 || return -1; fi
            REQUIREMENTS_FILE=$2; 
            shift 2 ;;
        -x | --export )
            EXPORT_REQUIREMENTS=true; shift ;;
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



# echo "PYTHONCMD=[$PYTHONCMD]"
PVERSION=$($PYTHONCMD --version 2>&1 | awk '{print $2}')
# echo "PVERSION=[$PVERSION]"

ENVNAMECOMESFROMENV=false
if [ "$CUSTOM_ENVNAME" = false ] && [ -n "$DEF_PTOOLS_ENVNAME" ]; then
    ENVNAME=$DEF_PTOOLS_ENVNAME
    ENVNAMECOMESFROMENV=true
fi
PMANAGER_COMESFROMENV=false
if [ -n "$DEF_PTOOLS_PACKAGEMANAGER" ]; then
    PACKAGEMANAGER=$DEF_PTOOLS_PACKAGEMANAGER
    PMANAGER_COMESFROMENV=true
fi
echo "# Working with python version: $PVERSION ($PYTHONCMD)." 
echo "# Package manager: $PACKAGEMANAGER $([ "$PMANAGER_COMESFROMENV" = true ] && echo " (It comes from DEF_PTOOLS_PACKAGEMANAGER env var)")"
echo "# ENVROOTFOLDER=[$ENVROOTFOLDER]"
echo "# ENVNAME=[$ENVNAME] $([ "$ENVNAMECOMESFROMENV" = true ] && echo " (It comes from DEF_PTOOLS_ENVNAME env var)")"
PYTHONENV=$ENVROOTFOLDER/$ENVNAME/bin  
if [ "$SHOWHELP" = true ]; then
    echo -e $(help);
    [ "$CALLMODE" == "executed" ] && exit 0 || return 0;
fi

if [ "$LISTENVS" = true ]; then
    echo "# Available envs in $ENVROOTFOLDER folder:"
    ls -1 "$ENVROOTFOLDER" | sed 's/^/- /'
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
if [ "$CREATE" = true ]; then
    echo "# Creating python env $ENVNAME in $ENVROOTFOLDER..."
    sudo mkdir -p  $ENVROOTFOLDER
    if [ -d "$ENVROOTFOLDER/$ENVNAME" ]; then
        MSG="WARNING: $ENVROOTFOLDER/$ENVNAME already exists. Do you want to overwrite it? (y/n)"
        read -p "$MSG " -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf $ENVROOTFOLDER/$ENVNAME
        fi
    fi
    if [ ! -d "$ENVROOTFOLDER/$ENVNAME" ]; then
        if [ $PACKAGEMANAGER == "pip" ]; then
            CMD="$PYTHONCMD -m venv --copies $ENVROOTFOLDER/$ENVNAME"
        else
            CMD="$PACKAGEMANAGER create -y -p $ENVROOTFOLDER/$ENVNAME"
        fi
    echo "# Running command: [$CMD]"
    read -p "Press [ENTER] to continue or [CTRL+C] to abort"
    $CMD        
    fi
fi

if [ "$ACTIVATE" = true ]; then
    echo "# Activating python env $ENVROOTFOLDER/$ENVNAME..."
    if [ $PACKAGEMANAGER == "pip" ]; then
        CMD="source $PYTHONENV/activate";
    else
        CMD="$PACKAGEMANAGER activate $ENVROOTFOLDER/$ENVNAME"
    fi
    echo "# Running command: [$CMD]"
    read -p "Press [ENTER] to continue or [CTRL+C] to abort"
    $CMD        
fi
if [ -n "$REQUIREMENTS_FILE" ]; then
    echo "# Installing requirements from $REQUIREMENTS_FILE..."
    read -p "Press [ENTER] to continue or [CTRL+C] to abort"
    if [ $PACKAGEMANAGER == "pip" ]; then
        $PACKAGEMANAGER install --no-cache-dir -r $REQUIREMENTS_FILE
    else
        $PACKAGEMANAGER install --file $REQUIREMENTS_FILE
    fi
fi

if [ "$EXPORT_REQUIREMENTS" = true ]; then
    if [ $PACKAGEMANAGER == "pip" ]; then
        echo "# Running command pip list --not-required --format=freeze to export the list of installed packages..."
        echo "# pip freeze --all can also be used to include all dependencies"
        $PACKAGEMANAGER list --not-required --format=freeze
    else
        echo "# Running command conda list --explicit --md5 to export the list of installed packages..."
        $PACKAGEMANAGER list --explicit --md5
    fi
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if [ "$DEACTIVATE" = true ]; then
    echo "Deactivating python env $PYTHONENV..."
    if [ $PACKAGEMANAGER == "pip" ]; then
        deactivate
    else
        $PACKAGEMANAGER deactivate
    fi
fi
