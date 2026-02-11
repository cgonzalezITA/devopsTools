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
# \t[-y|--yes]: No confirmation questions are asked \n
ASK=true

# \t-v: Do not show verbose info                                                    \n
VERBOSE=true

GITROOTFOLDER=$(git rev-parse --show-toplevel)
# \t-f <fileWithFiles2BFrozen>: def .gitfrozen. File with the files to be frozen    \n
FILESWITHFILES2BFROZEN=$(git rev-parse --show-toplevel)/.gitfrozen
ACTION=""
ACTIONS=" freeze f unfreeze u stash unstash info "
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [-h] [-f <fileWithFiles2BFrozen>] [<action:$ACTIONS>]                         \n
        \tThis tool freezes or unfreezes a set of git already commited files.                                    \n
        \tThis can be applied to config files or .env files that store private info                              \n
        \tnot intented to be saved.                                                                              \n
        \tSee https://medium.com/@adi.ashour/dont-git-angry-skip-in-worktree-e9c77dec9d15                        \n
        \t, https://www.baeldung.com/ops/git-assume-unchanged-skip-worktree                                      \n
        \t---                                                                                                    \n
        \t-h: Show help info                                                                                     \n
        \t[-y|--yes]: No confirmation questions are asked \n
        \t-v: Do not show verbose info                                                                           \n
        \t-f <fileWithFiles2BFrozen>: def .gitfrozen. File with the files to be frozen                           \n
        \t<action:freeze*|f|unfreeze|u|stash|unstash>: Specifies one action to perform over the files            \n
        \t- freeze|f: Freezes (skip-worktree) the files                                                          \n
        \t- unfreeze|u: Unfreezes (no-skip-worktree) the files                                                   \n
        \t- stash: Stash the files. This is useful when changing branches (git checkout)                         \n
        \t- unstash: unstash the files. This is useful when changing branches (git checkout)                     \n
        \t- info: Show list of frozen files                                                                      \n
        \tNOTE: If a git checkout operation gives error due to these frozen files perform the following actions: \n
        \t      $SCRIPTNAME stash                                                                                \n
        \t      git checkout <newBranch>                                                                         \n
        \t      $SCRIPTNAME unstash"
    echo $HELP
    return $#;
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
             [ "$CALLMODE" == "executed" ] && exit -1 || return -1; ;;
        -v | --verbose ) 
            VERBOSE=false; shift ;;
        -y | --yes ) 
            ASK=false; shift ;;
        -f ) 
            FILESWITHFILES2BFROZEN=$2
            if ! test -f $FILESWITHFILES2BFROZEN; then 
                echo -e $(help "ERROR: File $FILESWITHFILES2BFROZEN must exist"); 
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
             fi
            shift ; shift ;;
        -u ) 
            ACTION="--no-skip-worktree"
            shift ;;        
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#ACTION}" -eq 0; then
                ACTION=$1
            fi
            shift;
    esac
done

if test "${#ACTION}" -eq 0; then 
ACTION="f"
fi
if [[ ! ${ACTIONS[@]} =~ " $ACTION " ]];  then
    echo -e $(help "ERROR: Unknown action. It must be one of [$ACTIONS]")
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif [ "$ACTION" == "f" ]; then
    ACTION="--skip-worktree"        
elif [ "$ACTION" == "u" ]; then
    ACTION="--no-skip-worktree"        
fi

if [ "$VERBOSE" = true ]; then
    echo "  - GITROOTFOLDER= [$GITROOTFOLDER]"
    echo "  - ACTION= [$ACTION]"
    echo "  - FILESWITHFILES2BFROZEN= $FILESWITHFILES2BFROZEN"
fi

FILES=""
NFILES=0
while IFS= read -r file; do 
    file="$GITROOTFOLDER/$file"
    # echo "file=$file"
    if test -f "$file"; then 
        FILES="$FILES \"$file\""
        NFILES=$(($NFILES+1))
    else
        echo -e $(help "ERROR: File [$file] does not exist. Please review the file $FILESWITHFILES2BFROZEN. It must contain the names of the files to be [$ACTION]")
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
done < <(cat $FILESWITHFILES2BFROZEN; echo)

if test "$NFILES" -eq 0; then
     echo -e $(help "No files to be [$ACTION] has been found in file $FILESWITHFILES2BFROZEN")
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif [ "$VERBOSE" = true ]; then
    echo -e "  - FILES2BFROZEN ($NFILES)= [$FILES]\n---"

fi

if [ "$ACTION" == "info" ]; then
    echo "List of frozen files:"
    CMD="git ls-files -v | grep '^S'"
    echo "Running command [$CMD]"
    PWD1=$(pwd)
    cd $GITROOTFOLDER
    bash -c "$CMD"
    cd $PWD1
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif [ "$ACTION" == "--skip-worktree" ] || [ "$ACTION" == "--no-skip-worktree" ]; then
    CMD1="git update-index $ACTION $FILES"; 
    CMD2=""
elif [ "$ACTION" == "stash" ] || [ "$ACTION" == "unstash" ]; then
    if [ "$ACTION" == "stash" ]; then
        CMD1="git update-index --no-skip-worktree $FILES";
        CMD2="git stash push -m \"Stashing frozen file changes\" $FILES"; 
    else        
        CMD1="git stash pop"; 
        CMD2="git update-index --skip-worktree $FILES";
    fi
fi

if [ "$ASK" = true ]; then
    if [ ! -z "${CMD1}" ]; then
        echo -e "  1st. Run command [$CMD1]"; 
    fi
    if [ ! -z "${CMD2}" ]; then
        echo -e "  2nd. Run command [$CMD2]"; 
    fi
    MSG=$(echo "QUESTION: Are you sure to run the previous command/s [Y/n]?")
    read -p "$MSG" -n 1 -r
    echo    # (optional) move to a new line
else
    REPLY="y"
fi
if [[ $REPLY =~ ^[Yy]$ ]]
then
    if [ "$VERBOSE" = true ]; then
        bash -c "$CMD1"; 
    fi
    if [ "$VERBOSE" = true ] && test "${#CMD2}" -gt 0; then
        bash -c "$CMD2"; 
    fi

    if [ "$VERBOSE" = true ]; then
        echo "List of frozen files after command/s:"
        PWD1=$(pwd)
        cd $GITROOTFOLDER
        CMD="git ls-files -v | grep '^S'"
        echo "Running command [$CMD]"
        eval $CMD
        cd $PWD1
    fi
fi