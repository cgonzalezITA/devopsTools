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
#  "USAGE getFile: Syntax getFile BASEDIR USEFCLUE FCLUE ask"
# Returns the file matching the FCLUE. If several appear, a list of them is presented for the user to choose just one
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi

    # echo "  Hello getFile ("$#") ($getFile_result) $1 $2 $3 $4 $5 $6 $7" > /dev/tty
    FCLUEISDIR=false;
    ask=false;
    FILEINFOLDER=""
    if test "$#" -lt 4; then
        # export getFile_result=
        echo "Error getFiles: Syntax getFile BASEDIR USEFCLUE FCLUE FCLUEBASE [ask(false) FCLUEISDIR(false) FILEINFOLDER("") ACTIONDESC SEARCHINSUBFOLDERS]"
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi;
    BASEDIR=$1; shift;
    # BASEDIR=$(echo $BASEDIR | sed 's/ /\\ /g')
    USEFCLUE=$1; shift;
    FCLUE=$1; shift;
    # FCLUE=$(echo $FCLUE | sed 's/ /\\ /g')
    FCLUEBASE=$1; shift;

    [[ "$#" -ge 1 ]] && ask=$1; shift;
    [[ "$#" -ge 1 ]] && FCLUEISDIR=$1; shift;
    [[ "$#" -ge 1 ]] && FILEINFOLDER=$1; shift;
    [[ "$#" -ge 1 ]] && { ACTIONDESC="$1"; shift; } || ACTIONDESC=""; 
    [[ "$#" -ge 1 ]] && { SEARCH_SUBFOLDER=false; MAXDEPTH=1; shift; } || MAXDEPTH=10; 
    # echo "BASEDIR=$BASEDIR"           > /dev/tty;
    # echo "USEFCLUE=$USEFCLUE"         > /dev/tty;
    # echo "FCLUE=$FCLUE"               > /dev/tty;
    # echo "FCLUEBASE=$FCLUEBASE"       > /dev/tty;
    # echo "FCLUEISDIR=$FCLUEISDIR"     > /dev/tty;
    # echo "FILEINFOLDER=$FILEINFOLDER" > /dev/tty;
    # echo "ACTIONDESC=$ACTIONDESC"     > /dev/tty;
    # echo "SEARCHSUBFOLDER=$SEARCHSUBFOLDER" > /dev/tty;
    # echo "MAXDEPTH=$MAXDEPTH" > /dev/tty;

    COMMAND=choose
    if [ "$FCLUEISDIR" = true ]; then
        artifact=folder
        ARTIFACTTYPE=d
        FINDFCLUE="*${FCLUE}*"
    else
        artifact=files
        ARTIFACTTYPE=f
         FINDFCLUE="*${FCLUE}*"
    fi

    if [ "$USEFCLUE" = true ]; then        
        # echo "Using FCLUE of [$BASEDIR] [$FINDFCLUE]" > /dev/tty;
        # CMD="find $BASEDIR -type $ARTIFACTTYPE -name \"$FINDFCLUE\""
        # echo "Running CMD=$CMD"
        # for i in $MAXDEPTH
        for (( i=1; i<=$MAXDEPTH; i++ )); do
            CMD="find \"$BASEDIR\" -maxdepth $i -type $ARTIFACTTYPE -wholename \"$FINDFCLUE\""
            # echo -e "\nRunning CMD=[$CMD]" > /dev/tty;
            FCONFIG=$(eval $CMD)
            if [[ "${#FCONFIG}" -gt 0 ]]; then
                # echo "Found at level $i: FCONFIG=$FCONFIG" > /dev/tty;
                break;
            fi
        done
        
        # echo "FCONFIG=$FCONFIG"
    else
        FCONFIG=$FCLUE
    fi
    ITEMS=()
    IDX=1
    while IFS= read -r line ; do ITEMS="$ITEMS$line|"; IDX=$((++IDX)); done <<< "$FCONFIG"
    # https://unix.stackexchange.com/questions/353235/work-around-to-storing-array-values-in-an-environment-variable-then-calling-from        
    IFS='|'; set -f
    array=( $ITEMS )        # split it
    I0=${array[0]}
    NTIEMS=${#array[@]}
    # echo "Items found: $ITEMS; NTIEMS=$NTIEMS; I0=${#I0}"> /dev/tty
    if test "${#I0}" -eq 0; then
        # getFile_result=
        echo "$ACTIONDESC. No file matching the clue [$FCLUE] in folder [$BASEDIR]";
        if [ "$CALLMODE" == "executed" ]; then exit -2; else return -2; fi
    elif test "$NTIEMS" -eq 1; then
        IDX=0
        # If searching a file inside a directory, the directory has been found, just to check for the file inside it
        if [ "$FCLUEISDIR" = true ] && test "${#FILEINFOLDER}" -gt 0; then
            BASEDIR2=$(bash -c "echo \"${array[0]}\" | sed s#//*#/#g")
            CMD="$SCRIPTNAME \"$BASEDIR2\" true $FILEINFOLDER $FILEINFOLDER false false \"$ACTIONDESC\""
            # echo "Running CMD=$CMD" > /dev/tty
            getFileResult=$($SCRIPTNAME "$BASEDIR2" true $FILEINFOLDER $FILEINFOLDER false false "" "$ACTIONDESC");
            RC=$?; 
            if test "$RC" -ne 0; then 
                echo "  ERROR[$RC]: $getFileResult";
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#getFileResult}" -eq 0; then
                # Selected not to use the artifacts
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            else    
                FOUNDFILE=$getFileResult;
            fi
        else
            FOUNDFILE=${array[0]}
        fi

        if [ "$ask" = true ]; then
            read -p "$ACTIONDESC.  Do you want to [$COMMAND] [$artifact] [$FOUNDFILE]? ('y/n')" -n 1 -r
            if ! [[ $REPLY =~ ^[1|Y|y]$ ]]; then 
                # getFile_result="";
                echo "";
                if [ "$CALLMODE" == "executed" ]; then exit 0; else return 0; fi
            fi
        fi
        echo $FOUNDFILE
        if [ "$CALLMODE" == "executed" ]; then exit 0; else return 0; fi
    else
        IDX=1
        echo "  ${ACTIONDESC}. ${NTIEMS} [$artifact] found matching the clue [$FCLUE] in folder [$BASEDIR]:" > /dev/tty;
        while IFS= read -r line ; do 
            ITEMS="$ITEMS$line|"; 
            echo "    $IDX-$line" | sed "s/$FCLUEBASE/\x1b[31m&\x1b[0m/" > /dev/tty; 
            IDX=$((++IDX)); 
        done <<< "$FCONFIG"
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
                # getFile_result=
                echo $ERR
                if [ "$CALLMODE" == "executed" ]; then exit -3; else return -3; fi
            else
                IDX=$(( REPLY - 1 ))
            fi

            if [ "$FCLUEISDIR" = true ] && test "${#FILEINFOLDER}" -gt 0; then
                BASEDIR2=${array[$IDX]}
                CMD="$SCRIPTNAME \"$BASEDIR2\" true $FILEINFOLDER $FILEINFOLDER false false \"$ACTIONDESC\""
                # echo "Running CMD=$CMD"
                getFileResult=$($SCRIPTNAME "$BASEDIR2" true $FILEINFOLDER $FILEINFOLDER false false "$ACTIONDESC");
                RC=$?; 
                if test "$RC" -ne 0; then 
                    echo "  ERROR[$RC]: $getFileResult";
                    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
                elif test "${#getFileResult}" -eq 0; then
                    # Selected not to use the artifacts
                    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
                else    
                    FOUNDFILE=$getFileResult;
                fi
            else
                FOUNDFILE=${array[$IDX]}
            fi

        fi
        # echo "ITEMS AS ARRAY: [${#array[@]}]=${ITEMS}";
    fi
    # getFile_result=
    echo $FOUNDFILE
# }
