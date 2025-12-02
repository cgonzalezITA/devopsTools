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
# USAGE dServices: Syntax dServices <dockerFilePath> [<serviceClue>] [<verbose>] [<projectDir>] [<envFile>] [<profile>]
#       If more than a service matches the serviceClue, an interactive selection is presented to the user to choose one
# Returns the services matching the <serviceClue> in format servicesFound|serviceSelected
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi

if test "$#" -lt 1; then
    # export getContainers_result=
    echo "Error dService: Syntax Syntax dServices <dockerFilePath> [<serviceClue>] [<verbose>] [<projectDir>] [<envFile>] [<profile>]" > /dev/tty;
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi;
DOCKERCOMPOSE_FILE=$(echo "\"${1-}\"" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
SERVICECLUE=$(echo "\"${2-}\"" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
VERBOSE=${3-false}
PROJECTDIR=$(echo "\"${4-}\"" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
ENVFILE=$(echo "\"${5-}\"" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
PROFILES=$(echo "\"${6-}\"" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
# [ "$VERBOSE" = true ] && echo "\$1=$1" > /dev/tty;
# [ "$VERBOSE" = true ] && echo "\$2=$2" > /dev/tty;
# [ "$VERBOSE" = true ] && echo "\$3=$3" > /dev/tty;
# [ "$VERBOSE" = true ] && echo "\$4=$4" > /dev/tty;
# [ "$VERBOSE" = true ] && echo "\$5=$5" > /dev/tty;
# [ "$VERBOSE" = true ] && echo "\$6=$6" > /dev/tty;
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
CMD="$PRECOMMAND $DOCKERCOMPOSE_CMD -f $DOCKERCOMPOSE_FILE $PROJECTNAME $ENVFILE $PROJECTDIR config --services"
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
