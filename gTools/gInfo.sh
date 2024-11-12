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
PWD1=$(pwd)

#############################
## Functions               ##
#############################
function help() {
    HELP="HELP: USAGE: $SCRIPTNAME [-h] [-s <submodulePath>]"
    if test "$#" -ge 1; then
        HELP="${HELP}\n${1}"     
    fi
    echo $HELP
    return $#;
}


##############################
## Main code                ##
##############################

# getopts arguments
while true; do
    case "$1" in
        -v | --verbose ) 
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
             [ "$CALLMODE" == "executed" ] && exit -1 || return -1; ;;
        -s | --submodule | -f ) 
            SUBMODULE=$2
            if ! test -d $SUBMODULE; then 
                echo -e $(help "ERROR: Submodule folder [$SUBMODULE] must exist"); 
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
             fi
            shift ; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            fi
            break ;;
    esac
done

if [ "$VERBOSE" = true ]; then
    echo "  >     SUBMODULE= [$SUBMODULE]"
    echo "  >          PATH= $( pwd )"
fi

if test "${#SUBMODULE}" -gt 0; then
    cd $SUBMODULE;
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Git Root folder"
CMD="git rev-parse --show-toplevel"
GITROOTFOLDER=$($CMD)
echo "- $LABEL: $GITROOTFOLDER" | egrep --color=auto  "$LABEL" 
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Git name"
CMD="basename $GITROOTFOLDER"
GITNAME=$($CMD)
echo "- $LABEL: $GITNAME" | egrep --color=auto  "$LABEL" 
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Remote Origin"
CMD="git remote -v"
echo "- $LABEL:" | egrep --color=auto  "$LABEL" 
eval "$CMD"
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Current Branch"
CMD1="git rev-parse --abbrev-ref HEAD"
BRANCHNAME=$($CMD1)
CMD="git status -sb"
$CMD | grep $BRANCHNAME | grep origin > /dev/null 2>&1 && EXISTATORIGIN=true || EXISTATORIGIN=false
# echo "EXISTATORIGIN=$EXISTATORIGIN"
echo "- $LABEL: $BRANCHNAME (Does $BRANCHNAME Exist at origin? $EXISTATORIGIN)" | egrep --color=auto  "$LABEL" 
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD1]" 
    echo -e "> Run command [$CMD]" 
fi

cd $GITROOTFOLDER

if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Latest commit"
CMD="git branch -vv"
echo -e "- $LABEL:" | egrep --color=auto  "$LABEL"
$CMD | grep $BRANCHNAME | sed "s/\($BRANCHNAME\)/\x1b[31m\1\x1b[0m/g"
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Changes pending to commit"
CMD="git status -sb"
echo -e "- $LABEL:" | egrep --color=auto  "$LABEL" 
$CMD
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Pending commits to push"
CMD="git log origin/$BRANCHNAME ..HEAD --oneline"
echo -e "- $LABEL:" | egrep --color=auto  "$LABEL" 
$CMD > /dev/null 2>&1 
RC=$?
if test "$RC" -eq 0; then
    $CMD
elif test $EXISTATORIGIN; then
    echo "Info no available"
else
    echo "Info no available as branch does not exist at origin";
fi
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Existing branches"
CMD="git branch -vva"
echo -e "- $LABEL:" | egrep --color=auto  "$LABEL" 
if [ "$VERBOSE" = true ]; then
    echo "NOTE: If you still see non existing branches, just run 'git remote prune origin' to get rid of them" | GREP_COLOR="1;32" egrep  --color=always "NOTE"
fi
$CMD
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Tags"
# CMD="git tag"
CMD="git show-ref --tags"
NTAGS=$($CMD | wc -l)
echo "- $LABEL ($NTAGS):" | egrep --color=auto  "$LABEL" 
$CMD
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Remote Tags"
CMD="git ls-remote --tags"
NTAGSREMOTE=$($CMD | grep  -v "\^{}" | wc -l)
echo "- $LABEL ($NTAGSREMOTE):" | egrep --color=auto  "$LABEL" 
$CMD |  grep  -v "\^{}"
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


if [ "$VERBOSE" = true ]; then
    echo "---"
fi
LABEL="Submodules"
# CMD="git config --file .gitmodules --get-regexp path "
CMD="git submodule foreach --recursive git remote get-url origin"
TXT=$($CMD)
if test ${#TXT} -gt 0; then
    echo -e "- $LABEL:\n$TXT" | egrep --color=auto  "$LABEL" 
    # | sed "s|Entering|  ${LABEL}:|g"  | sed "s/\($LABEL\)/\x1b[31m\1\x1b[0m/g"
else
    TXT="No Submodules detected on the GIT"
fi
LABEL="Submodule"
echo $TXT | sed "s|Entering|  ${LABEL}:|g"  | sed "s/\($LABEL\)/\x1b[31m\1\x1b[0m/g"
if [ "$VERBOSE" = true ]; then
    echo -e "> Run command [$CMD]" 
fi


cd $PWD1
