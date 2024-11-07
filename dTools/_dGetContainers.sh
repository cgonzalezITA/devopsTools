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
#  "USAGE getContainers: Syntax getContainers ARTIFACT USECCLUE CCLUE COMMAND askFlag [customColumn (:metadata.name)]"
# Returns the docker containers matching the cclue. If several appear, a list of them is presented for the user to choose just one
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi

if test "$#" -lt 5; then
    # export getContainers_result=
    echo "Error getContainers: Syntax getContainers ARTIFACT USECCLUE CCLUE COMMAND askFlag [customColumn with syntax {{.<columnName>}}] ACTIONDESC"
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi;
ARTIFACT=$1; shift
USECCLUE=$1; shift;
CCLUE=$1; shift;
COMMAND=$1; shift;
ask=$1; shift;
CUSTOMCOLUMN="{{.Names}}"
if test "$#" -ge 1; then
    CUSTOMCOLUMN=$1; shift
fi
if test "$#" -ge 1; then ACTIONDESC=$1; shift;  else  ACTIONDESC=""; fi
if test "$ARTIFACT" == "ps"; then
    ARTIFACTLS=""
    CUSTOMCOLUMN="{{.Names}}"
    ARTIFACT_FORMATIDS="{{.ID}}"
else
    ARTIFACTLS="ls"
    CUSTOMCOLUMN="{{.Name}}"
    if test "$ARTIFACT" == "volume"; then
        ARTIFACT_FORMATIDS="{{.Name}}"
    else
        ARTIFACT_FORMATIDS="{{.ID}}"
    fi
fi



CCOLUMNDEF="--format '$CUSTOMCOLUMN'"
if [ "$USECCLUE" = true ]; then
    CMD=$( echo "docker $ARTIFACT -a $ARTIFACTLS $CCOLUMNDEF")
    # echo "Running command $CMD"
    CNAME=$( bash -c "$CMD | grep $CCLUE")
else
    CMD=$( echo "docker $ARTIFACT -a $ARTIFACTLS --filter 'name=$CCLUE' $CCOLUMNDEF 2> /dev/null")
    # echo "Running command2 $CMD"
    CNAME=$( bash -c "$CMD | grep -w \"$CCLUE\"")
    RC=$?; 
    if test "$RC" -ne 0; then 
        echo "" # No pod has been found!
    else
        echo $CNAME
    fi
    if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
fi
# echo "CNAME=$CNAME"
ITEMS=()
IDX=1
while IFS= read -r line ; do ITEMS="$ITEMS$line|"; IDX=$((++IDX)); done <<< "$CNAME"
# https://unix.stackexchange.com/questions/353235/work-around-to-storing-array-values-in-an-environment-variable-then-calling-from        
IFS='|'; set -f
array=( $ITEMS )        # split it
I0=${array[0]}
NTIEMS=${#array[@]}
# echo "Items found: $ITEMS; NTIEMS=$NTIEMS; I0=${#I0}"> /dev/tty
if test "${#I0}" -eq 0; then
    # getContainers_result=
    echo "$ACTIONDESC. No pods matching the clue [$CCLUE]";
    if [ "$CALLMODE" == "executed" ]; then exit -2; else return -2; fi
elif test "$NTIEMS" -eq 1; then
    if [ "$ask" = true ]; then
        CMDWITHGREP="docker $ARTIFACT -a $ARTIFACTLS"
        IDX=1
        while IFS= read -r line ; do 
            ITEMS="$ITEMS$line|"; 
            ITEM=$(bash -c "$CMDWITHGREP | grep $line$");
            echo "$IDX-$ITEM" | grep "$CCLUE" | egrep --color=auto  "$line|$"> /dev/tty; 
            IDX=$((++IDX)); 
        done <<< "$CNAME"
        read -p "  $ACTIONDESC. Do you want to [$COMMAND] container [${array[0]}]? ('y/n')" -n 1 -r
        if ! [[ $REPLY =~ ^[1|Y|y]$ ]]; then 
            # getContainer_result="";
            echo "";
            if [ "$CALLMODE" == "executed" ]; then exit 0; else return 0; fi
        fi
    fi
    IDX=0 # Will returns item 0 on success
else
    echo "  $ACTIONDESC. ${NTIEMS} containers found matching the clue [$CCLUE]:" > /dev/tty;
    # CMDWITHGREP=$( echo $CMD | sed 's/\-\-format '\''{{\.Names}}'\''//g')
    IDX=1
    CMDWITHGREP="docker $ARTIFACT -a $ARTIFACTLS"
    while IFS= read -r line ; do 
        ITEMS="$ITEMS$line|"; 
        ITEM=$(bash -c "$CMDWITHGREP | grep $line$");
        echo "$IDX-$ITEM" | grep "$CCLUE" | sed "s/$line/\x1b[31m&\x1b[0m/" > /dev/tty; 
        IDX=$((++IDX)); 
    done <<< "$CNAME"
    read -p "  $ACTIONDESC. Select the number of element to [$COMMAND] (1-$NTIEMS) or 'n' to skip: " -n 1 -r
    echo "" > /dev/tty;
    if [[ $REPLY =~ ^[n]$ ]]; then 
        echo "";
        if [ "$CALLMODE" == "executed" ]; then exit 0; else return 0; fi
    else
        ERR=""
        if [[ "$REPLY" =~ ^[0-9]+$ ]]; then
            if ((REPLY > NTIEMS || REPLY <= 0)); then
                ERR="[$REPLY]: Wrong index chosen"
            fi
        else
            ERR="[$REPLY] is not a number"
        fi
        if test "${#ERR}" -gt 0; then
            ERR="$ERR. It Should have been a number between 1 and $NTIEMS"
            # getContainers_result=
            echo $ERR
            if [ "$CALLMODE" == "executed" ]; then exit -3; else return -3; fi
        else
            IDX=$(( REPLY - 1 ))
        fi
    fi
    # echo "ITEMS AS ARRAY: [${#array[@]}]=${ITEMS}";
fi
echo ${array[$IDX]}
