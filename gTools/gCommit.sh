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
FOLDER_VALUES=./HValues
VERBOSE=true
SUBMODULE=""
PWD1=$(pwd)
C1=""
C2=""
# \t[-y|--yes]: No confirmation questions are asked \n
ASK=true
# \t[-t|--tag] TAG: Adds a tag to commit \n
# \t[-f| -ft |--ftag] TAG: Forces an existing tag to be updated to the committed head \n
TAG=""
# \t[-tc|--tagComment] TAGCOMMENT: Adds a comment to the tag\n"
TAGC=""

#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [-h] [-s <submodulePath>] <comment1 (with quotes \")> [<comment2 (with quotes \")>] [-t TAG] [-tc TAGCOMMENT] \n
            \t-h: Show help info \n
            \t-y: No confirmation questions are asked \n
            \t[-t|--tag] TAG: Adds a tag to commit \n
            \t[-f| -ft |--forcetag] TAG: Forces an existing tag to be updated to the committed head \n
            \t[-tc|--tagComment] TAGCOMMENT: Adds a comment to the tag\n
            \tMulti-line commit via heredoc: $SCRIPTNAME << 'EOF'\n\t  subject line\n\t  \n\t  body paragraph\n\tEOF\n"
    echo $HELP
    HELP="HELP: USAGE: $SCRIPTNAME "
}


##############################
## Main code                ##
##############################

# getopts arguments
while true; do
    [[ "$#" -eq 0 ]] && break;
    case "$1" in
        -v | --verbose ) 
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
             [ "$CALLMODE" == "executed" ] && exit -1 || return -1; ;;
        -a | --ask ) 
            VERBOSE=false; shift ;;
        -y | --yes ) 
            ASK=false; shift ;;
        -t | --tag ) 
            TAG="-a \"$2\""; shift; shift ;;
        -f | -ft | --forcetag ) 
            TAG="-f \"$2\""; shift; shift ;;
        -tc | --tagComment ) 
            TAGC=$2; shift; shift ;;
        -s | --submodule | -f | -m ) 
            SUBMODULE=$2
            if ! test -d $SUBMODULE; then 
                echo -e $(help "ERROR: Submodule folder [$SUBMODULE] must exist"); 
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
             fi
            shift ; shift ;;
        * ) 
            if [[ $1 =~ ^-[a-zA-Z0-9-] ]]; then
                echo -e "WARNING: Unknown parameter [$1]";
            elif test "${#C1}" -eq 0; then
                if [[ "$1" == *$'\n'* ]]; then
                    C1="\$(cat << 'EOF' 
$1
EOF)"
                else
                    C1="$1"
                fi
                
            elif test "${#C2}" -eq 0; then
                if [[ "$1" == *$'\n'* ]]; then
                    C2="\$(cat << 'EOF' 
$1
EOF)"
                else
                    C2="$1"
                fi
            fi
            shift ;;
    esac
done

if test "${#C1}" -eq 0; then
    echo -e $(help "ERROR: <comment1 (with quotes \")> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if test "${#TAG}" -gt 0; then
    test "${#TAGC}" -eq 0 && TAGC=$C1;
fi
if [ "$VERBOSE" = true ]; then
    echo "---"
    echo " PATH= $( pwd )"
    echo " SUBMODULE= [$SUBMODULE]"
    echo " C1= [$C1]"
    echo " C2= [$C2]"
    echo " TAG= [$TAG]"
    echo " TAGCOMMENT=[$TAGC]"
fi
COMMIT_ARGS=("-m" "$C1")
test "${#C2}" -gt 0 && COMMIT_ARGS+=("-m" "$C2")
CMD="git commit -m \"$C1\""
test "${#C2}" -gt 0 && CMD="$CMD -m \"$C2\""
if test "${#TAG}" -gt 0; then
    CMD="$CMD; git tag $TAG -m \"$TAGC\""
fi
if [ "$VERBOSE" = true ]; then
    echo "---"
    echo "  >Running command [$CMD]"
fi
if [ "$ASK" = true ]; then
    MSG=$(echo "QUESTION: Are you sure to run the previous command to commit the git changes [Y/n]?" \
                | sed "s/\(to commit the git changes\)/\x1b[31m\1\x1b[0m/g")
    read -p "$MSG" -n 1 -r < /dev/tty
    echo    # (optional) move to a new line
else
    REPLY="y"
fi
if [[ $REPLY =~ ^[Yy]$ ]]
then
    if test "${#SUBMODULE}" -gt 0; then
        cd $SUBMODULE;
    fi
    echo ---
    git commit "${COMMIT_ARGS[@]}"
    if test "${#TAG}" -gt 0; then
        eval "git tag $TAG -m \"$TAGC\""
    fi
    cd $PWD1
fi
