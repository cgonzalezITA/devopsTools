#!/bin/bash
#********************************************************************************
# DevopsTools
# Version: 1.0.0 
# Copyright (c) 2025 Instituto Tecnologico de Aragon (www.ita.es)
# Date: October 2025
# Authors: 
#          Carlos Gonzalez Muñoz                    cgonzalez@ita.es
# All rights reserved 
#********************************************************************************
# USAGE dServices: dServices --file dockerFile [--file dockerFile2 ...] [-s serviceClue] [-v] [-p <projectDir>] [-e <envFile>] [-pr <profile>]
#       If more than a service matches the serviceClue, an interactive selection is presented to the user to choose one
# Returns the services matching the <serviceClue> in format servicesFound|serviceSelected
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi

DOCKERCOMPOSE_FILE_ARGS=""
SERVICECLUE=""
VERBOSE=false
PROJECTDIR=""
ENVFILE=""
PROFILES=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -f | --file )
            DOCKERCOMPOSE_FILE_ARGS="$DOCKERCOMPOSE_FILE_ARGS -f $2"
            shift; shift ;;
        -s )
            SERVICECLUE="$2"
            shift; shift ;;
        -v | --verbose )
            VERBOSE=true
            shift ;;
        -p | --project-directory )
            PROJECTDIR="--project-directory \"$2\""
            shift; shift ;;
        -e | --env-file )
            ENVFILE="--env-file \"$2\""
            shift; shift ;;
        -pr | --profile )
            PROFILES="$2"
            shift; shift ;;
        * )
            echo "WARNING: Unknown parameter [$1]" > /dev/tty
            shift ;;
    esac
done
if [ "${#DOCKERCOMPOSE_FILE_ARGS}" -eq 0 ]; then
    echo "Error dService: Syntax dServices --file dockerFile [--file dockerFile2 ...] [-s serviceClue] [-v] [-p <projectDir>] [-e <envFile>] [-pr <profile>]" > /dev/tty;
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
DOCKERCOMPOSE_CMD="docker compose"
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
            && echo "WARNING: No docker compose command has been detected. Is it installed?" > /dev/tty;
    fi
fi

PRECOMMAND=""
[ "${#PROFILES}" -gt 0 ] && PRECOMMAND="COMPOSE_PROFILES=$PROFILES"
CMD="$PRECOMMAND $DOCKERCOMPOSE_CMD $DOCKERCOMPOSE_FILE_ARGS $PROJECTNAME $ENVFILE $PROJECTDIR config --services"
[ "$VERBOSE" = true ] && echo "Running CMD=$CMD" 2>/dev/null > /dev/tty;
SERVICES=$(eval $CMD 2>/dev/null)
RC=$?; 
if test "$RC" -ne 0; then 
    echo -e "---\nError running command1 [${CMD}]" > /dev/tty;
    echo -e "ERROR: Docker compose services retrieval returned error $RC" > /dev/tty;
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if test "${#SERVICECLUE}" -gt 0; then 
    FILTERED_SERVICES=$(printf '%s\n' "$SERVICES" | grep -F -- "$SERVICECLUE" || true)
    # echo "Services in docker compose matching $SERVICECLUE: [$FILTERED_SERVICES]" > /dev/tty;
    SERVICES=" $(echo $SERVICES | sed 's/\n//g') "
    
    # Count matches (ignore empty lines, just in case)
    MATCH_COUNT=$(printf '%s\n' "$FILTERED_SERVICES" | sed '/^$/d' | wc -l)
    if [ "$MATCH_COUNT" -eq 0 ]; then
        echo "---" > /dev/tty
        echo -e "ERROR: No services match clue [$SERVICECLUE]. Available services are [$SERVICES]" > /dev/tty
        [ "$CALLMODE" == "executed" ] && exit 1 || return 1
    elif [ "$MATCH_COUNT" -eq 1 ]; then
        # Single match → assign to SERVICECLUE
        SERVICENAME=$(printf '%s\n' "$FILTERED_SERVICES" | sed -n '1p')
        # echo "Unique match. Selected service: [$SERVICENAME]" > /dev/tty
    else
        # Multiple matches → interactive selection
        echo "Select one of the services matching clue '$SERVICECLUE':" > /dev/tty

        i=1
        while IFS= read -r svc; do
            [ -z "$svc" ] && continue
            echo "  $i) $svc" > /dev/tty
            i=$((i+1))
        done <<< "$FILTERED_SERVICES"

        # Ask user to choose
        while :; do
            printf "Service number [1-%s]: " "$MATCH_COUNT" > /dev/tty
            read -r choice < /dev/tty

            # Basic numeric validation
            case "$choice" in
                '' )
                    echo "No selection. Aborting." > /dev/tty
                    [ "$CALLMODE" == "executed" ] && exit 1 || return 1
                    ;;
                *[!0-9]* )
                    echo "Please enter a number between 1 and $MATCH_COUNT." > /dev/tty
                    ;;
                * )
                    if [ "$choice" -ge 1 ] && [ "$choice" -le "$MATCH_COUNT" ]; then
                        break
                    else
                        echo "Invalid selection. Choose between 1 and $MATCH_COUNT." > /dev/tty
                    fi
                    ;;
            esac
        done

        # Pick the selected line
        SERVICENAME=$(printf '%s\n' "$FILTERED_SERVICES" | sed -n "${choice}p")
        # echo "Selected service: [$SERVICENAME]" > /dev/tty
    fi
fi
SERVICES=" $(echo $SERVICES | sed 's/\n//g') "
[ "$VERBOSE" = true ] && echo "Services in docker compose: [$SERVICES]" > /dev/tty;
echo "$SERVICES|$SERVICENAME"
