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
# \t-g <gitURL>: URL Base of the git server (eg. https://git.itainnova.es/). If not provided,                                                   \n
GITURL=""
# \t-t <accessToken>: Private token generated with API permissions (See https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html),  \n
ACCESSTOKEN=""
GITPROJECTINFO=""
#############################
## Functions               ##
#############################
function help() {
    HELP="HELP: USAGE: $SCRIPTNAME [-h] [-g <gitURL> -t <accessToken> | -f <fileWithGitProjectInfo>] <submoduleClue>                                                                    \n 
            \t-h: Show help info                                                                                                                        \n
            \t-v: Do not show verbose info                                                                                                              \n
            \t-g <gitURL>: URL Base of the git server (eg. https://git.itainnova.es/). If not provided,                                                 \n
            \t-f <fileWithGitProjectInfo>: Mainly for debugging, skips the burdensome step of requesting data to the git server                         \n
            \t-t <accessToken>: Private token generated with API permissions (See https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html), \n
            \t <submoduleClue>: Clue to identify the git submodule to get its references"
    if test "$#" -ge 1; then
        HELP="${HELP}\n${1}"     
    fi
    echo $HELP
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
        -g | --gitUrl ) 
            GITURL=$2
            shift ; shift ;;
        -t | --accessToken ) 
            ACCESSTOKEN=$2
            shift ; shift ;;
        -f )
            GITPROJECTINFOFILE=$2
            GITPROJECTINFO=$(cat $GITPROJECTINFOFILE);

            RC=$?
            if test "${RC}" -ne 0; then
                echo -e $(help "ERROR: Error Reading $GITPROJECTINFOFILE file. Does it exist?");
                exit -1
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

if test "$#" -lt 1; then
    echo -e $(help "ERROR: <submoduleClue> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
else
    MCLUE=$1; shift;
fi

if test "${#GITPROJECTINFO}" -eq 0; then
    if test "${#ACCESSTOKEN}" -eq 0; then
        echo -e $(help "ERROR: -t (--accessToken) <accessToken> is mandatory");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi

    getGitURL() {
        echo "Extracting GIT URL assuming current folder is inside a GIT project..."
        GITURL=$(git remote get-url origin)
        RC=$?;
        if test "${RC}" -ne 0; then
            echo -e $(help "ERROR: Retrieving git URL of current GIT. Are you in a GIT folder?");
            exit -1
        fi
        # Extract the domain and repo path
        if [[ "$GITURL" == https* ]]; then
            # HTTPS URL: Use as-is
            full_url="$GITURL"
        else
            # SSH URL: Convert to HTTPS
            domain=$(echo "$GITURL" | cut -d'@' -f2 | cut -d':' -f1)
            repo_path=$(echo "$GITURL" | cut -d':' -f2)
            
            # Construct HTTPS URL
            GITURL="https://$domain/$repo_path"
        fi

        # Output the full HTTPS URL
        GITURL=$(echo "$GITURL" | cut -d'/' -f1-3)
        if curl --head --silent --fail $GITURL 1> /dev/null;
        then
            return 0;
        else
            echo -e $(help "ERROR: Server $GITURL not reachable. Try specifying correct gitURL base via -g parameter");
            exit -2
        fi
    }

    if test "${#GITURL}" -eq 0; then
        getGitURL # Generates the GITURL
    fi
fi # GITPROJECTINFO

if [ "$VERBOSE" = true ]; then
    echo "  GITPROJECTINFOFILE=[$GITPROJECTINFOFILE]"
    echo "  GITURL=[$GITURL]"
    echo "  ACCESSTOKEN=[${ACCESSTOKEN}]"
    echo "  MCLUE=[$MCLUE]" | egrep --color=auto  "$MCLUE"    
fi

if test "${#GITPROJECTINFO}" -eq 0; then
    # Get all GITPROJECTINFO (paginated)
    GITPROJECTINFO=$(curl --header "PRIVATE-TOKEN: $ACCESSTOKEN" "$GITURL/api/v4/projects?membership=true&per_page=5000")
fi

# GITURL="https://gitlab.example.com"
# ACCESSTOKEN="<your-access-token>"
# SUBMODULE_URL="https://gitlab.example.com/group/project-X.git"  # The URL of the project X submodule

# echo "GITPROJECTINFO:$GITPROJECTINFO"
# Loop over each project
GIT_ID_NAMES=$(echo "$GITPROJECTINFO" | jq -r '.[] | .web_url')
echo $GIT_ID_NAMES | while read -r GIT_URL; do
    echo -e "GIT_URL=$GIT_URL\n"
#     project_name=$(echo "$GITPROJECTINFO" | jq -r --arg id "$project_id" '.[] | select(.id == ($id | tonumber)) | .name')
#     echo "project_name=$project_name"
#     echo "Checking project: $project_name ($project_id)"
# exit
#     # Check if the .gitmodules file exists in the project
#     gitmodules=$(curl --header "PRIVATE-TOKEN: $ACCESSTOKEN" "$GITURL/api/v4/projects/$project_id/repository/files/.gitmodules/raw?ref=master")

#     # If the .gitmodules file contains the submodule URL, print the project name
#     if echo "$gitmodules" | grep -q "$SUBMODULE_URL"; then
#         echo "Project '$project_name' contains submodule: $SUBMODULE_URL"
#     fi
done