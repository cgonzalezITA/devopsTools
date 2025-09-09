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
############################
## Variable Initialization #
############################
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
CURRDIR=$(pwd)
# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# \t[-j1b|just1branch]: Just 1 branch with text is required. Other branches of same repository will not be analyzed (def. false) \n
JUST1BRANCH=false
GIT_REPO=gitlab.ita.es
PAT=''
TEXT2FIND=''
WORKING_DIR_BASE=/tmp
# \t[-o|--output] <outputFile>: Writes the content into the <outputFile> (-y flag is set)\n
# OUTPUTFILE=""
# \t[-sa|--stopafter] <numReposWithText>: Stops crawling repos after <numReposWithText> have been found\n
STOPAFTER_REPOSWITHTEXT=9999
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t[-o|--output] <outputFile>: Writes the results into the <outputFile> \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <PERSONAL_ACCESS_TOKEN> <TextToFind> \n 
            \t-h: Show help info \n
            \t-v: Do not show verbose info\n
            \t-w|--working-dir <WORKING_DIR_BASE>: Working dir (def value: /tmp) with proper permissions\n
            \t-g <git_repository>: dns of the git repo. eg. github.com \n
            \t[-sa|--stopafter] <numReposWithText>: Stops crawling repositories after <numReposWithText> have been found\n
            \t[-j1b|just1branch]: Just 1 branch with text is required. Other branches of same repository will not be analyzed (def. true) \n
            \tPERSONAL_ACCESS_TOKEN: Git account's personal access token with permissions: api\n
            \tTextToFind: Text to find in the repositories \n"
    echo $HELP
}

##############################
## Main code                ##
##############################

# getopts arguments
while true; do
    [[ "$#" -eq 0 ]] && break;
    case "$1" in
        -v) 
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            break ;;
        # -o | --output )
        #     # \t[-o|--output] <outputFile>: Writes the content into the <outputFile> (-y flag is set)\n
        #     OUTPUTFILE=$2
        #     echo > ${OUTPUTFILE:-/dev/stdout}
        #     shift ; shift ;;
        -g | --git-repo )
            GIT_REPO=$2; 
            shift; shift ;;
        -sa | --stopafter )
            STOPAFTER_REPOSWITHTEXT=$2; 
            shift; shift ;;
        -j1b | --just1branch )
            JUST1BRANCH=true; 
            shift ;;
        -w | --working-dir )
            WORKING_DIR_BASE=$2; 
            shift; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#PAT}" -eq 0; then
                    PAT=$1
            elif test "${#TEXT2FIND}" -eq 0; then
                    TEXT2FIND=$1
            fi ;
            shift ;;
    esac
done


if test "${#PAT}" -eq 0; then
    echo -e $(help "ERROR: a PERSONAL_ACCESS_TOKEN is required"); 
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif test "${#TEXT2FIND}" -eq 0; then
    echo -e $(help "ERROR: Missing Text 2 find"); 
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

# Generate timestamp and folder name
TIMESTAMP=$(date +"%y%m%d-%H%M%S")
WORKING_DIR="${WORKING_DIR_BASE}/${TIMESTAMP}_gFindTextInRepos"
PROJECTS_FILE="$WORKING_DIR/projects.json"
if [ "$VERBOSE" = true ]; then
    echo -e "Searching repositories at $GIT_REPO for text '$TEXT2FIND' with parameters" # >> ${OUTPUTFILE:-/dev/stdout}; 
    echo -e "--------------------"            # >> ${OUTPUTFILE:-/dev/stdout}; 
    echo "VERBOSE=[$VERBOSE]"                 # >> ${OUTPUTFILE:-/dev/stdout}; 
    echo "WORKING_DIR_BASE=$WORKING_DIR_BASE" # >> ${OUTPUTFILE:-/dev/stdout}; 
    echo "WORKING_DIR=$WORKING_DIR"           # >> ${OUTPUTFILE:-/dev/stdout}; 
    echo "GIT_REPO=$GIT_REPO"                 # >> ${OUTPUTFILE:-/dev/stdout}; 
    echo "STOPAFTER_REPOSWITHTEXT=$STOPAFTER_REPOSWITHTEXT" # >> ${OUTPUTFILE:-/dev/stdout};
    echo "JUST1BRANCHREQUIRED=[$JUST1BRANCH]" # >> ${OUTPUTFILE:-/dev/stdout};
    echo "TEXT2FIND=[$TEXT2FIND]"             # >> ${OUTPUTFILE:-/dev/stdout};
    echo -e "--------------------\n"          # >> ${OUTPUTFILE:-/dev/stdout};
fi


# Create the directory
# if [ "$VERBOSE" = true ]; then
#     echo "Creating working dir $WORKING_DIR"
# fi
mkdir -p "$WORKING_DIR"

HEADERS="--header \"PRIVATE-TOKEN:${PAT}\" "

# List all projects
CMD="curl -s https://$GIT_REPO/api/v4/projects?per_page=1000 --header \"PRIVATE-TOKEN:<PAT>\" | jq '.[] | {name, path_with_namespace, http_url_to_repo, created_at, updated_at}'"
# if [ "$VERBOSE" = true ]; then
#     echo "Running CMD=$CMD > $PROJECTS_FILE"
# fi
CMD="curl -s https://$GIT_REPO/api/v4/projects?per_page=1000 $HEADERS \
    | jq '.[] | {name, path, path_with_namespace, http_url_to_repo, created_at, updated_at}'"
eval $CMD > "$PROJECTS_FILE"
if [ $? -ne 0 ]; then
    echo "ERROR: Command failed"
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

eval jq -s . "$PROJECTS_FILE" > "${PROJECTS_FILE}2"
eval mv "${PROJECTS_FILE}2" "$PROJECTS_FILE"

COUNT_REPOS=$(jq length $PROJECTS_FILE)
IDX_REPO=0
NUM_REPOS_WITHSTRING_TOTAL=0
NUM_FINDINGS=0
NUM_FINDINGS_TOTAL=0

if [ "$VERBOSE" = true ]; then
    echo -e "File '${PROJECTS_FILE}' created with the list of git projects at $GIT_REPO ($COUNT_REPOS)\n"
fi

# jq -c '.[]' "$PROJECTS_FILE" | while read -r entry; do
while read -r entry; do
    name=$(echo "$entry" | jq -r '.name')
    path=$(echo "$entry" | jq -r '.path')
    url=$(echo "$entry" | jq -r '.http_url_to_repo')
    url_with_pat=$(echo "$url" | sed "s#://$GIT_REPO#://oauth2:${PAT}@${GIT_REPO}#")
    
    IDX_REPO=$((IDX_REPO+1))   
    
    # CMD="git clone --quiet $url_with_pat $REPO_FOLDER"
    # if [ "$VERBOSE" = true ]; then
    #     echo "Running CMD=$CMD"
    # fi
    # eval $CMD
    # if [ $? -ne 0 ]; then
    #     echo "ERROR: Cloning repo $name($url) failed"
    # fi
    # cd $REPO_FOLDER
    FOUND=false
    REPO_FOLDER="$WORKING_DIR/$path"
    mkdir -p "$REPO_FOLDER"
    # For each branch in the repo
    # git ls-remote --heads "$url_with_pat" | while read -r _ ref; do
    mapfile -t BRANCHES < <(git ls-remote --heads "$url_with_pat" | awk '{print $2}' | sed 's#refs/heads/##')
    MSG="- Searching for '$TEXT2FIND' in repo $IDX_REPO/$COUNT_REPOS '$name'; branches: [$(IFS=,; echo "${BRANCHES[*]}"; unset IFS)]' ($url)"
    if [ "$VERBOSE" = true ]; then
        echo  "$MSG";
    fi
    
    for branch in "${BRANCHES[@]}"; do
        BRANCH_FOLDER="$WORKING_DIR/$path/$branch"
        if [ -d "$BRANCH_FOLDER" ]; then
            rm -rf $BRANCH_FOLDER
        fi
        CMD="git clone --single-branch --branch $branch --quiet $url_with_pat $BRANCH_FOLDER"
        # if [ "$VERBOSE" = true ]; then
        #     echo "Running CMD=$CMD"
        # fi
        eval $CMD
        if [ $? -ne 0 ]; then
            echo "ERROR: Cloning repo $name:$branch($url) at $BRANCH_FOLDER failed"
        fi

        cd $BRANCH_FOLDER
        FINDINGS=$(git --no-pager grep -l "$TEXT2FIND" | paste -sd, -)
        NUM_FINDINGS=$(echo "$FINDINGS" | awk -F',' '{print NF==1 && $1=="" ? 0 : NF}')
        NUM_FINDINGS_TOTAL=$((NUM_FINDINGS_TOTAL+NUM_FINDINGS))
        cd $CURRDIR
        
        if [ "$NUM_FINDINGS" -gt 0 ]; then
            MSG2="$NUM_FINDINGS/$NUM_FINDINGS_TOTAL found at '$name:$branch'"
            echo  "  $MSG2: [$FINDINGS]";

            # if [ "$OUTPUTFILE" != "" ]; then            
            #     echo  -e "$MSG\n$MSG2: $FINDINGS" >> ${OUTPUTFILE};
            # fi       
        
            if [ "$FOUND" = false ]; then
                NUM_REPOS_WITHSTRING_TOTAL=$((NUM_REPOS_WITHSTRING_TOTAL+1))
                # echo "  Total repositories with findings: $NUM_REPOS_WITHSTRING_TOTAL vs $STOPAFTER_REPOSWITHTEXT";
                FOUND=true
            fi
            if [ "$JUST1BRANCH" = true ]; then
              break
            fi
        else
            rm -rf $BRANCH_FOLDER
        fi
    done

    if [[ "$NUM_REPOS_WITHSTRING_TOTAL" -ge "$STOPAFTER_REPOSWITHTEXT" ]]; then
        if [ "$VERBOSE" = true ]; then
            echo "Stopping after $NUM_REPOS_WITHSTRING_TOTAL repositories with text '$TEXT2FIND' have been found (stopafter=$STOPAFTER_REPOSWITHTEXT)"
        fi
        break
    fi
    # Delete a folder if it does not have any file nor subfolder
    if [ -d "$REPO_FOLDER" ] && [ -z "$(ls -A "$REPO_FOLDER")" ]; then
        rmdir "$REPO_FOLDER"
    fi
# done
done < <(jq -c '.[]' "$PROJECTS_FILE")

MSG="\n----------------------\nFinal summary: $NUM_FINDINGS_TOTAL files found with string '$TEXT2FIND' in $NUM_REPOS_WITHSTRING_TOTAL/$IDX_REPO repositories at '$GIT_REPO'"
echo -e $MSG
# if [ "$OUTPUTFILE" != "" ]; then          
#     echo $MSG >> ${OUTPUTFILE:-/dev/stdout}; 
# fi
cd $CURRDIR
if [ -d "$WORKING_DIR" ] && [ -z "$(ls -A "$WORKING_DIR")" ]; then
    rmdir "$WORKING_DIR"
fi