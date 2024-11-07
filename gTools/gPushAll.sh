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
# \t-y: No confirmation questions are asked                                                             \n
ASK=true
# \t-f: Force push even no changes have been detected (eg. when tags are created)\n"
FORCE=false
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME # Pushes all commits from the current git and its submodules                      \n
            \t-h: Show help info\n
            \t-y: No confirmation questions are asked\n
            \t-f: Force push even no changes have been detected (eg. when tags are created)\n"
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
            # echo "help rc=$?"
            if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
            break ;;
        -y | --yes ) 
            ASK=false; shift ;;
        -f | --force ) 
            FORCE=true; shift ;;
        * )  
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            fi ;;
    esac
done

echo -e "Pushing pending commits of current git and its submodules...\n---"

PWD1=$(pwd)
CMD="git rev-parse --show-toplevel"
GITROOTFOLDER=$($CMD)
CMD="basename $GITROOTFOLDER"
GITNAME=$($CMD)


cd $GITROOTFOLDER
# GITS=$(! find . -depth -name .git)

for dir in . */; do
  if [ -e "$dir/.git" ]; then
    cd "$dir" # && git pull)
    [ $dir == "." ] && dir=$(pwd);
    CMD="basename $dir"
    GITNAME=$($CMD)

    CMD="git rev-parse --abbrev-ref HEAD"
    BRANCHNAME=$($CMD)
    echo "Analyzing commits at $GITNAME (branch $BRANCHNAME)"

    CMD="git log origin/$BRANCHNAME..HEAD"
    $CMD > /dev/null 2>&1
    RC=$?
    test "$RC" -ne 0 && PENDINGCOMMITS="Unknown" || PENDINGCOMMITS=$($CMD | grep "commit")
    # echo "PENDINGCOMMITS=$PENDINGCOMMITS"
    # echo "LEN=${#PENDINGCOMMITS}"
    test "${#PENDINGCOMMITS}" -gt 0 && HASPENDINGCOMMITS=true ||  HASPENDINGCOMMITS=false
    # echo "HASPENDINGCOMMITS=$HASPENDINGCOMMITS"
    if [ "$FORCE" == true ] || [ "$HASPENDINGCOMMITS" == true ]; then
        echo -e "Pushing updates for $GITNAME" | sed "s|\($GITNAME\)|\x1b[31m\1\x1b[0m|g"        
        CMD="git status -sb"
        $CMD | grep $BRANCHNAME | grep origin > /dev/null 2>&1 && EXISTATORIGIN=true || EXISTATORIGIN=false
        if ! $EXISTATORIGIN; then
            CMD="git push --set-upstream origin $BRANCHNAME"
        else
            CMD="git push"
        fi
        # Check tags at remote and local
        NTAGSLOCAL=$(git tag | wc -l)
        NTAGSREMOTE=$(git ls-remote --tags | grep  "\^{}" | wc -l)
        if [ "$NTAGSLOCAL" -gt "$NTAGSREMOTE" ]; then
            echo "As Number of local tags ($NTAGSLOCAL) > number remote tags($NTAGSREMOTE), tags are asked to be pushed"
            CMD="$CMD --tags"
        fi
        if [ "$ASK" = true ]; then
            echo -e ">Running command [$CMD]" 
            MSG="QUESTION: Do you want to run the command to push changes of git [$GITNAME] at branch $branch [$BRANCHNAME]?"
            read -p "$MSG [Y/n]? " -n 1 -r 
                echo    # (optional) move to a new line
        else
            REPLY="y"
        fi
        if [[ $REPLY =~ ^[1Yy]$ ]]; then
            bash -c "$CMD"
            RC=$?
            if test "$RC" -ne 0; then 
                echo "Command finished with RC code=$RC"
            fi
        fi

        if [ "$NTAGSLOCAL" -gt "$NTAGSREMOTE" ]; then
            CMD="git push"
            if [ "$ASK" = true ]; then
                echo -e ">Running command [$CMD]" 
                MSG="QUESTION: Do you want to run the command to push changes of git [$GITNAME] at branch $branch [$BRANCHNAME]?"
                read -p "$MSG [Y/n]? " -n 1 -r 
                    echo    # (optional) move to a new line
            else
                REPLY="y"
            fi
            if [[ $REPLY =~ ^[1Yy]$ ]]; then
                bash -c "$CMD"
                RC=$?
                if test "$RC" -ne 0; then 
                    echo "Command finished with RC code=$RC"
                fi
            fi
        fi
        

    else
        echo "INFO: No pending commits detected at $GITNAME (branch $BRANCHNAME)" | GREP_COLOR="1;32" egrep  --color=always "INFO"
    fi
    echo -e '---'
  fi
done

cd $PWD1