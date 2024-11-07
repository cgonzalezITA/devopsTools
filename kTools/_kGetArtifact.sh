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
#  "USAGE getArtifacts: Syntax getArtifact artifactName USECCLUE CCLUE NAMESPACEARG COMMAND askFlag [customColumn (:metadata.name)]"
# Returns the k8s artifact matching the cclue. If several appear, a list of them is presented for the user to choose just one
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi

# function getArtifact() { # <artifactName> <fvalue> <podClue>
    # export getArtifact_result=""
    # echo "  Hello getArtifact ("$#") ($getArtifact_result) $1 $2 $3 $4 $5 $6" > /dev/tty
    if test "$#" -lt 6; then
        # export getArtifact_result=
        echo "Error getArtifacts: Syntax getArtifact artifactName USECCLUE CCLUE NAMESPACEARG COMMAND askFlag [customColumn (:metadata.name)]"
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi;
    artifact=$1; shift;
    USECCLUE=$1; shift;
    CCLUE=$1; shift;
    NAMESPACEARG=$1; shift;
    COMMAND=$1; shift;
    ask=$1; shift;
    CUSTOMCOLUMN=":metadata.name"
    if test "$#" -ge 1; then
        CUSTOMCOLUMN=$1; shift
        # If a field different than the name is to be retrieved, the CCLUE has to be exact as it will not appear in the customColumn
        CCOLUMNDEF="custom-columns='$CUSTOMCOLUMN'"
        CMD=$( echo "kubectl get $artifact $NAMESPACEARG $CCLUE --no-headers -o $CCOLUMNDEF")
        CNAME=$( bash -c "$CMD")
    elif [ "$USECCLUE" = true ]; then
        CCOLUMNDEF="custom-columns='$CUSTOMCOLUMN'"
        CMD=$( echo "kubectl get $artifact $NAMESPACEARG --no-headers -o $CCOLUMNDEF")
        CNAME=$( bash -c "$CMD  | grep $CCLUE")
    else
        CCOLUMNDEF="custom-columns='$CUSTOMCOLUMN'"
        CMD=$( echo "kubectl get $artifact $CCLUE $NAMESPACEARG --no-headers -o $CCOLUMNDEF 2> /dev/null")
        CNAME=$( bash -c "$CMD")
        RC=$?; 
        if test "$RC" -ne 0; then 
            echo "" # No pod has been found!
        else
            echo $CNAME
        fi
        if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
    fi
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
        # getArtifact_result=
        echo "No [$artifact] matching the clue [$CCLUE] at namespace [$NAMESPACEARG]";
        if [ "$CALLMODE" == "executed" ]; then exit -2; else return -2; fi
    elif test "$NTIEMS" -eq 1; then
        IDX=0
       if [ "$ask" = true ]; then
            read -p "  Do you want to [$COMMAND] [$artifact] [${array[0]}]? ('y/n')" -n 1 -r
            if ! [[ $REPLY =~ ^[Y|y]$ ]]; then 
                # getArtifact_result="";
                echo "";
                if [ "$CALLMODE" == "executed" ]; then exit 0; else return 0; fi
            fi
        fi
    else
        IDX=1
        echo "  ${NTIEMS} [$artifact] found matching the clue [$CCLUE] in NameSpace[$NAMESPACEARG]:" > /dev/tty;
        CMDWITHGREP=$( echo "$CMD" | sed 's/'\-o\ custom-columns=\'':metadata.name'\''//g')
        while IFS= read -r line ; do 
            ITEMS="$ITEMS$line|"; 
            ITEM=$(bash -c "$CMDWITHGREP | grep \"^$line \"");
            echo "$IDX-$ITEM" | sed "s/$CCLUE/\x1b[31m&\x1b[0m/" > /dev/tty; 
            IDX=$((++IDX)); 
        done <<< "$CNAME"
        read -p "  Select the number of element to [$COMMAND] (1-$NTIEMS) or 'n' to skip: " -n 1 -r
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
                # getArtifact_result=
                echo $ERR
                if [ "$CALLMODE" == "executed" ]; then exit -3; else return -3; fi
            else
                IDX=$(( REPLY - 1 ))
            fi
        fi
        # echo "ITEMS AS ARRAY: [${#array[@]}]=${ITEMS}";
    fi
    # getArtifact_result=
    echo ${array[$IDX]}
# }
