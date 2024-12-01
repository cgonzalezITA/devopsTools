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
VERBOSECMD=""
# \t<command>: Command to be executed inside the pod"
COMMAND=""
# \t-f <folder with helm config>: Folder where the config file must be located (def value: ./HValues    \n
FOLDER_VALUES=./
# \t-df <dockerCompose file>: def. docker-compose.yml                                                   \n
USEDFCLUE=true
# \t[-ff | --forceFolder]: Restricts search of the docker-compose file just on the -f folder. def. false \n
SEARCH_SUBFOLDERS=false
# \t-b: Build the docker compose images                                                                 \n
BUILDCMD=""
PRECOMMAND=""
# \t-d: Do not detach                                                                                   \n
DETACHCMD="--detach"
# \t<Service to use>: def. all. Name of the Service to perform the command on.                          \n
SERVICENAME=""
SERVICEDESC=""
# \t[-y|--yes]: No confirmation questions are asked \n
ASK=true

EXTRACMDS=""
COMMANDSAVAILABLE=" up start install u down stop del d restart r debug info "

# \tpdir <Project directory>: def. Folder where the docker-compose is located   \n
PROJECTDIR=""
# \t-p <Project name>: Deploy the docker compose as a project with the given name                 \n
PROJECTNAME=""
# \t-env <envFile>: Specifies a custom .env file (def=.env)                                       \n
ENVFILE=""
#############################
## Functions               ##
#############################
function help() {
    HELP=""
    if test "$#" -ge 1; then
        HELP="${1}\n"
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] [<command:def: up>][<service2Use>]                                            \n 
            \t-h: Show help info; -v: Do not show verbose info \n
            \t[-y|--yes]: No confirmation questions are asked \n
            \t-f <folder with docker-compose file>:                                                                               \n
            \t[-ff | --forceFolder]: Restricts search of the docker-compose file just on the -f folder. def. false \n
            \t-df <dockerCompose file>: def. docker-compose.yml                                                                   \n
            \t-dc <dockerCompose command>: docker-compose*, docker compose, ...                                                   \n
            \t                    export DOCKERCOMPOSE_CMD=<DockerComposeCommnad> to avoid having to repeat it on this commands   \n
            \t-pdir <Project directory>: def. Folder where the docker-compose is located                                          \n
            \t-p <Project name>: Deploy the docker compose as a project with the given name                                       \n
            \t-env <envFile>: Specifies a custom .env file (def=.env)                                                             \n
            \t-b: Build the docker compose images                                                                                 \n
            \t-d: Do not detach                                                                                                   \n
	        \t<command>: Command to be executed: One of ($COMMANDSAVAILABLE)                                                      \n
            \t<Service to use>: def. all. Name of the Service to perform the command on."
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
            VERBOSECMD=$1;
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            # echo "help rc=$?"
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            break ;;
        -y|--yes )
            # \t[-y|--yes]: No confirmation questions are asked \n
            ASK=true
            shift ;;
        -f ) 
            FOLDER_VALUES=$2
            SEARCH_SUBFOLDERS=false
            if ! test -d $FOLDER_VALUES; then 
                echo -e $(help "ERROR: Folder [$FOLDER_VALUES] must exist");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            fi
            shift ; shift ;;
        -ff | --forceFolder)
            # \t[-ff | --forceFolder]: Restricts search of the docker-compose file just on the -f folder. def. false \n
            SEARCH_SUBFOLDERS=true
            shift;;
        -df ) 
            USEDFCLUE=false
            DOCKERCOMPOSE_FILE=$2
            shift ; shift ;;
        -pdir | --project-directory) 
            PROJECTDIR=$2
            shift ; shift ;;
        -env | --env-file ) 
            ENVFILE=$2
            shift ; shift ;;
        -dc ) 
            DOCKERCOMPOSE_CMD=$2
            shift ; shift ;;
        -p | --projectname ) 
            PROJECTNAME=$2
            shift; shift ;;
        -b | --build ) 
            PRECOMMAND="BUILDKIT_PROGRESS=plain "
            BUILDCMD="--build"; shift ;;
        -d | --detach ) 
            DETACHCMD=""; shift ;;            
        * ) 
            if [[ $1 == -* && $1 != --* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#COMMAND}" -eq 0; then
                COMMAND=$1
                shift;
            elif test "${#SERVICENAME}" -eq 0; then
                SERVICENAME=$1;
                shift;
            fi ;;
    esac
done

[[ "${#COMMAND}" -eq 0 ]] && COMMAND="up";

if [[ ! ${COMMANDSAVAILABLE[@]} =~ " $COMMAND " ]]
then
    # echo "value not found: $PROVIDEDPARAMS"
# Swapping is done between COMMAND AND SERVICENAME
    if [[ "$PROVIDEDPARAMS" -le 1 ]]; then
        SERVICENAME=$COMMAND
        COMMAND=up
    else
        TMP=$SERVICENAME
        SERVICENAME=$COMMAND
        COMMAND=$TMP
    fi
fi

if [ "$USEDFCLUE" = true ]; then
    shopt -s expand_aliases
    . ~/.bash_aliases
    getFileResult=$(_fGetFile "$FOLDER_VALUES" true "docker-compose.y*ml" "docker-compose" false $SEARCH_SUBFOLDERS);
    RC=$?; 
    if test "$RC" -ne 0; then 
        echo -e $(help "ERROR: $getFileResult");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    elif test "${#getFileResult}" -eq 0; then
        # Selected not to use the artifacts
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    else    
        DOCKERCOMPOSE_FILE=$getFileResult;
    fi
    if ! test -f "$DOCKERCOMPOSE_FILE"; then 
        echo -e $(help "ERROR: docker compose file $DOCKERCOMPOSE_FILE must exist");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
fi

if [[ ! ${COMMANDSAVAILABLE[@]} =~ " $COMMAND " ]]
then
#    echo "value not found: $PROVIDEDPARAMS"
# Swapping is done between COMMAND AND SERVICENAME
    if [[ "$PROVIDEDPARAMS" -le 1 ]]; then
        SERVICENAME=$COMMAND
        COMMAND=up
    else
        TMP=$SERVICENAME
        SERVICENAME=$COMMAND
        COMMAND=$TMP
    fi
fi




# Code
# echo "DOCKERCOMPOSE_CMD=$DOCKERCOMPOSE_CMD"
if [[ -z "${DOCKERCOMPOSE_CMD}" ]]; then
    # Sets the proper docker compose command
    DOCKERCOMPOSE_CMD='docker-compose'
    DC_CMD_VERSION=$($DOCKERCOMPOSE_CMD --version 2> /dev/null)
    RC=$?
    if [[ "$RC" -ne 0 ]]; then
        DOCKERCOMPOSE_CMD="docker compose";
        DC_CMD_VERSION=$($DOCKERCOMPOSE_CMD version 2> /dev/null) 
        RC=$?
        [[ "$RC" -ne 0 ]] \
            && echo "WARNING: No docker compose file has been detected. Use -dc <DC_CMD> to set the valid one. Trying now with [$DOCKERCOMPOSE_CMD]";
    fi
fi

if [[ "${#DOCKERCOMPOSE_FILE}" -gt 0 ]]; then
    DC_FILEDESC=$DOCKERCOMPOSE_FILE;
    if [ "${DOCKERCOMPOSE_FILE:0:1}" == "/" ]; then
        DOCKERCOMPOSE_FILE="$DOCKERCOMPOSE_FILE";
    else
        DOCKERCOMPOSE_FILE="$(pwd)/$DOCKERCOMPOSE_FILE";
    fi
    DOCKERCOMPOSE_FILE=$(echo "$DOCKERCOMPOSE_FILE" | sed 's/ /\\ /g')
fi
[[ "${#PROJECTNAME}" -gt 0 ]] && PROJECTNAME="-p $PROJECTNAME";
[[ "${#ENVFILE}" -gt 0 ]] && ENVFILE="--env-file \"$ENVFILE\"";
[[ "${#PROJECTDIR}" -gt 0 ]] && PROJECTDIR="--project-directory \"$PROJECTDIR\"";
[[ "$COMMAND" =~ ^(debug|info)$ ]] && COMMAND="info";

CMD="$DOCKERCOMPOSE_CMD -f $DOCKERCOMPOSE_FILE $PROJECTNAME $PROJECTDIR config --services"
SERVICES=$(eval $CMD)
RC=$?; 
if test "$RC" -ne 0; then 
    [ "$VERBOSE" = true ] && echo -e "---\nRunning command1 [${CMD}]"
    echo -e $(help "ERROR: Docker compose services retrieval returned error $RC")
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
SERVICES=" $(echo $SERVICES | sed 's/\n//g') "

if [[ "$COMMAND" =~ ^(up|start|install|u)$ ]]; then
    COMMAND="up";
elif [[ "$COMMAND" =~ ^(down|stop|del|d)$ ]]; then
    if test "${#SERVICENAME}" -gt 0; then 
        COMMAND="rm -f ";
    else
        COMMAND="down";
    fi
fi


if [ "$COMMAND" == "info" ] || [ "$VERBOSE" == true ]; then
    echo "- ASK=[$ASK]"
    echo "- DOCKERCOMPOSE_CMD=[$DOCKERCOMPOSE_CMD ($DC_CMD_VERSION)]"
    echo "- DOCKERCOMPOSE_FILE=[$DC_FILEDESC]"
    echo "- PROJECTDIR=[$PROJECTDIR]"
    echo "- PROJECTNAME=[$PROJECTNAME]"
    echo "- ENVFILE=[$ENVFILE]"
    echo "- COMMAND=[$COMMAND]"
    echo "- BUILD=[$BUILDCMD]"
    echo "- DETACH=[$DETACHCMD]"
    echo "- SERVICES IN DOCKERCOMPOSE=[$SERVICES]"
    echo "- SERVICENAME=[$SERVICENAME]"
fi


if [[ "$COMMAND" =~ ^(restart|r)$ ]]; then
    COMMAND="restart";
    [ "$VERBOSE" = true ] && echo -e "---\n# INFO: Restarting docker compose $DC_FILEDESC $SERVICEDESC...";
    CMD="$SCRIPTNAME -v -df $DOCKERCOMPOSE_FILE $PROJECTDIR $ENVFILE $PROJECTNAME down $SERVICENAME"
    [ "$VERBOSE" = true ] && echo "  Running command 1/2 [${CMD}]";w
    bash -c "$CMD"
    RC=$?; 
    if test "$RC" -ne 0; then 
        [ "$VERBOSE" = true ] && echo "---"
        echo -e $(help "ERROR: Stopping service $SERVICENAME");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
    sleep 1
    # Chapuza para invertir el flag detach
    if test "${#DETACHCMD}" -eq 0; then
        DETACHCMD="--detach"
    else
        DETACHCMD=""
    fi
    CMD="$SCRIPTNAME -df $DOCKERCOMPOSE_FILE $PROJECTDIR $ENVFILE $DETACHCMD $BUILDCMD $PROJECTNAME up $SERVICENAME"
    [ "$VERBOSE" = true ] && echo "  Running command 2/2 [${CMD}]"
    [ "$VERBOSE" = true ] && echo "---"
    bash -c "$CMD"
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi


if test "${#SERVICENAME}" -gt 0; then 
    if [[ ! ${SERVICES[@]} =~ " $SERVICENAME " ]]
    then
        echo -e $(help "ERROR: Service [$SERVICENAME] must be one of [$SERVICES]");
        if [ "$CALLMODE" == "executed" ]; then exit 1; else return 1; fi
    fi
fi

if [[ "$COMMAND" =~ ^(debug|info)$ ]]; then
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif [ "$COMMAND" == "up" ]; then
    EXTRACMDS="$DETACHCMD $BUILDCMD"
elif [ "$COMMAND" == "rm -f " ]; then
    CMD="$PRECOMMAND $DOCKERCOMPOSE_CMD -f $DOCKERCOMPOSE_FILE $PROJECTDIR $ENVFILE $PROJECTNAME stop $SERVICENAME"
    [ "$VERBOSE" = true ] && echo "Running command [$CMD $SERVICEDESC]"
    if [ "$ASK" = true ]; then
        MSG="QUESTION: Do you want to run previous command?"
        read -p "$MSG [Y/n]? " -n 1 -r 
        [ "$VERBOSE" = true ] && echo    # (optional) move to a new line
    else
        REPLY="y"
    fi
    if [[ $REPLY =~ ^[1Yy]$ ]]; then
        /bin/bash -c "$CMD"
        RC=$?; 
        if test "$RC" -ne 0; then 
            [ "$VERBOSE" = true ] && echo "---"
            echo -e $(help "ERROR: Stopping service $SERVICENAME");
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
        fi
    fi
fi

CMD="$PRECOMMAND $DOCKERCOMPOSE_CMD -f $DOCKERCOMPOSE_FILE $PROJECTDIR $ENVFILE $PROJECTNAME $COMMAND $EXTRACMDS $SERVICENAME"
[ "$VERBOSE" = true ] && echo -e "---\nRunning CMD=$CMD $SERVICEDESC"
if [ "$ASK" = true ]; then
    MSG="QUESTION: Do you want to run the previous command?"
    read -p "$MSG [Y/n]? " -n 1 -r 
        echo    # (optional) move to a new line
else
    REPLY="y"
fi

if [[ $REPLY =~ ^[1Yy]$ ]]; then
    /bin/bash -c "$CMD";
fi