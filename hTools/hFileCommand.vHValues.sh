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

# \t-n <NamespaceClue>: Specifies a clue of the namespace to be used                                    \n
NSCLUE=""
NAMESPACE="default"
NAMESPACESET=false
NAMESPACEDESC="in default namespace."
NAMESPACEARG=""
# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# \t[<command>] Command to be executed against the artifact file: apply*|delete|restart"
COMMAND=install
# \t-f <folder with helm config>: Folder where the config file must be located (def value: ./HValues    \n
FOLDER_VALUES=./HValues
# \t-fv: Force secretname match the given clue (using this, the clue is not a clue, but the name)       \n
USECCLUE=true
# EXTRACOMPONENTS=""
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
# \t-b: Runs a dependency build command that is required for umbrella charts for being updated          \n
BUILDCMD=""
#############################
## Functions               ##
#############################
function help() {
    HELP="HELP: USAGE: $SCRIPTNAME [optArgs] <component clue> [<command>:install*|delete|restart|debug|test]\n 
            \t-h: Show help info                                                                                  \n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used                                    \n
            \t-f <folder with helm config>: Folder where the config file must be located (def value: ./HValues    \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)            \n
            \t-fnv: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
            \t-v: Do not show verbose info                                                                        \n
            \t-b: Runs a dependency build command that is required for umbrella charts for being updated          \n
            \t<component clue>: Clue to identify the artifact file name. all to run command on all yaml files     \n
            \t[<command>] Command to be executed against the artifact file: apply*|delete|restart|debug|test"
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
        -v ) 
            VERBOSE=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
            break ;;
        -fv | --forcevalue ) 
            USECCLUE=false; shift ;;
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; 
            shift ;;
        -b | --build ) 
            BUILDCMD="-b"; shift ;;
        -f ) 
            FOLDER_VALUES=$2
            if ! test -d $FOLDER_VALUES;then 
                echo -e $(help "ERROR: Folder [$FOLDER_VALUES] must exist");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            fi
            shift ; shift ;;
        -n | --namespace ) 
            # echo analyzing ns=$2;
            NAMESPACESET=true
            NSCLUE=$2
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
    echo -e $(help "# ERROR: <component clue> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if test "${#NSCLUE}" -gt 0; then
    if [ "$USENSCCLUE" = true ]; then
        shopt -s expand_aliases
        . ~/.bash_aliases
        NAMESPACEORERROR=$( _kGetNamespace $NSCLUE );
        RC=$?; 
    else
        NAMESPACEORERROR=$NSCLUE;
        RC=$?; 
    fi
    if test "$RC" -ne 0; then 
        echo -e $(help "$NAMESPACEORERROR"); 
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi;
    NAMESPACE=$NAMESPACEORERROR;
    NAMESPACEDESC="in [$NAMESPACE] namespace"; 
    NAMESPACEARG="-n $NAMESPACE"; 
fi

CCLUE=$1
shift;
if test "$#" -ge 1; then
    COMMAND=$1
fi

if [[ "$CCLUE" =~ ^(all)$ ]]; then
    # echo "CCLUE=* deploys all the files in the specified folder, so the -f <folder> has to be used"
    USECCLUE=false
    FCONFIG=$CCLUE
fi
if [ "$USECCLUE" = true ]; then
    shopt -s expand_aliases
    . ~/.bash_aliases
    getFileResult=$(_fGetFile "$FOLDER_VALUES" "$USECCLUE" "hConfig-*$CCLUE*.*" "$CCLUE" false);
    RC=$?; 
    if test "$RC" -ne 0; then 
        echo -e $(help "  ERROR: $getFileResult");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    elif test "${#getFileResult}" -eq 0; then
        # Selected not to use the artifacts
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    else    
        FCONFIG=$getFileResult;
    fi
else
    FCONFIG=$CCLUE
fi

# if [ "$USECCLUE" = true ]; then
#     FCONFIG=$(find $FOLDER_VALUES -maxdepth 1 -name "hConfig-*$CCLUE*.*")
# else
#     FCONFIG=$CCLUE
# fi

# if test "${#FCONFIG}" -eq 0; then
#     echo -e $(help "# ERROR: No hConfig file has been found for helm component clue [$CCLUE]");
#     [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
# fi
# NLINES=$(echo "$FCONFIG" | wc -l)
# if test "$NLINES" -ne 1; then
#     echo -e $(help "# ERROR: helm component clue [$CCLUE] is too generic. [$NLINES] config matches have been found: [$FCONFIG]")
#     [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
# fi

if [[ ${FCONFIG##*.} =~ json ]]; then
    JQ_YML_CMD=jq
elif [[ ${FCONFIG##*.} =~ ya?ml ]]; then
    JQ_YML_CMD="yq eval"
else
    echo -e $(help "# ERROR: Config file [$FCONFIG] must be json (*.json) or yaml (*.yaml)")
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi


CNAME=`$JQ_YML_CMD '.name'      $FCONFIG | tr -d '"'`
CCHART=`$JQ_YML_CMD '.chart'     $FCONFIG | tr -d '"'`
FVALUES=`$JQ_YML_CMD '.valueFile' $FCONFIG | tr -d '"'`
VERSION=`$JQ_YML_CMD '.version'   $FCONFIG | tr -d '"'`
# EXTRACOMPONENTS=`$JQ_YML_CMD '.extraComponents'   $FCONFIG | tr -d '"'`
# if [ "$EXTRACOMPONENTS" == null ]; then 
#     EXTRACOMPONENTS="";
# fi
if [ "$NAMESPACESET" == false ]; then
    NAMESPACECFG=`$JQ_YML_CMD '.namespace' $FCONFIG | tr -d '"'`
    if [ ! "$NAMESPACECFG" == null ]; then
        NAMESPACE=$NAMESPACECFG
        NAMESPACEDESC="in namespace [$NAMESPACE]"; 
        NAMESPACEARG="-n $NAMESPACE";
        USENSCCLUE=false
    fi
fi
if [ "$FVALUES" == "null" ]; then
# if test "${#FVALUES}" -eq 0; then
    echo -e $(help "# INFO: json.valueFile not found. Looking for value file in [$FOLDER_VALUES] folder");
    FVALUES=$(find $FOLDER_VALUES -maxdepth 1 -name "$CCLUE*-values.yml")
    if test "${#FVALUES}" -eq 0; then
        echo -e $(help "# ERROR: No yaml values file has been found for helm component clue [$CCLUE]");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
    NLINES=$(echo "$FVALUES" | wc -l)
    if test "$NLINES" -ne 1; then
        echo -e $(help "# ERROR: helm component clue [$CCLUE] is too generic. [$NLINES] matches have been found: [$FVALUES]")
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
fi

if test "${#CCHART}" -eq 0; then
    echo -e $(help "# INFO: Missing json 'chart' in [$FCONFIG]. Trying to use 'path' instead");
    CPATH=`$JQ_YML_CMD '.path' $FCONFIG | tr -d '"'`
    if test "${#CPATH}" -eq 0; then
        echo -e $(help "# ERROR: Missing json 'path' in [$FCONFIG]");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    else
        CCHART=$CPATH
    fi
fi


if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
    VERSIONDESC=""
    VERSIONARG=""
else
    VERSIONDESC="using VERSION [$VERSION]"
    VERSIONARG="--version $VERSION"
fi

if [[ "$COMMAND" =~ ^(up|start|install|u)$ ]]; then
    COMMAND="install";
elif [[ "$COMMAND" =~ ^(down|stop|del|d)$ ]]; then
    COMMAND="delete";
elif [ "$COMMAND" == "debug" ]; then
    COMMAND="template --debug";
fi


if [ "$VERBOSE" = true ]; then
    echo -e "#  >NAMESPACE=$NAMESPACECFG           "
    if test "${#NAMESPACE}" -gt 0; then echo -e "# -NAMESPACE=[$NSCLUE] -> [$NAMESPACE]"; else echo "# -NAMESPACE=[$NSCLUE] -> [$NAMESPACE]"; fi
    echo -e "# -CONFIGS_FOLDER=[$FOLDER_VALUES]    " 
    echo -e "# -CONFIG_FILE=[$CCLUE] -> [$FCONFIG] " 
    echo -e "# -COMMAND=[$COMMAND]                 " 
    echo -e "#  >HELM_NAME=$CNAME                  " 
    echo -e "#  >HELM_CHART=$CCHART                " 
    echo -e "#  >VERSION=$VERSIONARG               "
    echo -e "#  >HELM_VALUES=$FVALUES              " 
    if test "${#BUILDCMD}" -gt 0; then echo -e "#  >BUILD=$BUILDCMD"; fi
fi

if [ "$FCONFIG" == "all" ]; then
    IDX=1
    CMDF="find $FOLDER_VALUES -maxdepth 1 -name hConfig-*.* -type f"
    NFILES=$( /bin/bash -c "$CMDF | wc -l")
    echo "NFILES=$NFILES"
    X=""
    for filename in $(/bin/bash -c "$CMDF"); do
        CMDA="$SCRIPTNAME $BUILDCMD -v -fnv $NAMESPACEARG -f $FOLDER_VALUES -fv $filename $COMMAND"
        # CMDA="$SCRIPTNAME $NAMESPACEARG -v -f \"\" -fv $filename $COMMAND"
        # CMDA="helm $COMMAND $NAMESPACEARG -f $filename"
        echo -e "---\nINFO ($IDX/$NFILES): Executing command [$CMDA]"
        IDX=$(($IDX+1))
        # { err=$(cmd 2>&1 >&3 3>&-); } 3>&1
        X1=$($CMDA 2>&1)
        echo "$X1"
        X="$X\n\t---From file $filename---\n$X1"
    done
    echo -e "---\nSummary:\n$X"
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
echo -e "# INFO: Executing helm command [$COMMAND] using values from file [$FVALUES] for component [$CNAME] and chart [$CCHART] $VERSIONDESC $NAMESPACEDESC"



if test "$COMMAND" == "test"; then
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif [[ "$COMMAND" =~ ^(restart|r)$ ]]; then
    COMMAND="restart";
    # echo "# INFO: Restarting helm [$CNAME] $VERSIONDESC $NAMESPACEDESC"
    # echo "Running $SCRIPTNAME $CNAME delete $NAMESPACE..."
    # echo "$SCRIPTNAME -v -n $NAMESPACE -f $FOLDER_VALUES $CNAME delete..."
    echo " INFO: 1. Deleting helm [$CNAME]:"
    CMD="$SCRIPTNAME -fnv $NAMESPACEARG -fv $FCONFIG delete"
    echo -e "# Running command $CMD\n---"
    bash -c "$CMD"
    echo "---"
    echo " INFO: 2. Installing helm [$CNAME]:"
    sleep 1
    # echo "Running $SCRIPTNAME $CNAME install $NAMESPACE..."
    CMD="$SCRIPTNAME $BUILDCMD -fnv $NAMESPACEARG $BUILDCMD -fv $FCONFIG install"
    echo -e "# Running command $CMD\n---"
    bash -c "$CMD"
    if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
fi

# EXTRACOMPONENTS_FILE=/tmp/extraComponents.yaml
# if test -f $EXTRACOMPONENTS_FILE; then
#     rm $EXTRACOMPONENTS_FILE > /dev/null 2>&1
# fi
# if [ ! -z "${EXTRACOMPONENTS}" ]; then
#     echo -e "This config file has extra components:\n---\n$EXTRACOMPONENTS\n---"
#     read -ep "Do you want to you $COMMAND them ([Y/n])? (File $EXTRACOMPONENTS_FILE will be created)" -n 1 -r
#     echo    # (optional) move to a new line
#     if [[ $REPLY =~ ^[Yy]$ ]]; then 
#         # echo -e "apiVersion: v1\nkind: List\nmetadata:\nresourceVersion: ""\nitems:\n\t"
#         echo -e "$EXTRACOMPONENTS" > $EXTRACOMPONENTS_FILE
#     fi
# fi

if test -d $CCHART && [ "${#BUILDCMD}" -gt 0 ]; then # Only CCHART=directory apply the --build
    CMD="helm $NAMESPACEARG dependency update $CCHART $VERSIONARG"
    echo -e "Running command $CMD\n---"
    bash -c "$CMD"
    echo "---"
    CMD="helm $NAMESPACEARG dependency build $CCHART $VERSIONARG"
    echo -e "Running command $CMD\n---"
    bash -c "$CMD"
    echo "---"
fi

if [ "$COMMAND" == "template --debug" ]; then
    # if test -f $EXTRACOMPONENTS_FILE; then
    #     echo -e "$EXTRACOMPONENTS\n---"
    # fi
    # echo "# INFO: Running command helm $NAMESPACEARG $COMMAND -f $FVALUES $CNAME $CCHART"
    CMD="helm $NAMESPACEARG $COMMAND -f $FVALUES $CNAME $CCHART $VERSIONARG 2>&1"
    echo -e "# Running command $CMD\n---"
    bash -c "$CMD"
    echo "---"

elif [ "$COMMAND" == "install" ]; then
    # if test -f $EXTRACOMPONENTS_FILE; then
    #     echo "--- Applying extra components ---"
    #     kubectl $NAMESPACEARG apply -f $EXTRACOMPONENTS_FILE
    # fi
    # if [ "${#BUILDCMD}" -gt 0 -a $CCHART != "*.tgz" ]; then # To avoid the "Error: only unpacked charts can be updated" error
    CMD="helm $NAMESPACEARG $COMMAND -f $FVALUES $CNAME $CCHART $VERSIONARG --create-namespace"
    echo -e "# Running command $CMD\n---"
    bash -c "$CMD"
    echo "---"
elif [ "$COMMAND" == "delete" ]; then
    # echo "# INFO: Deleting helm $CNAME..."
    CMD="helm $NAMESPACEARG $COMMAND $CNAME"
    # if test -f $EXTRACOMPONENTS_FILE; then
    #     echo "--- extra components ---"
    #     echo "NOTE: If PV are not deleted, do not worry, or check https://stackoverflow.com/questions/55672498/kubernetes-cluster-stuck-on-removing-pv-pvc"
    #     kubectl $NAMESPACEARG delete -f $EXTRACOMPONENTS_FILE
    # fi
    echo -e "# Running command $CMD\n---"
    bash -c "$CMD"
    echo "---"
else
    echo "# ERROR: Unknown command [$COMMAND]"
fi
# if test -f $EXTRACOMPONENTS_FILE; then
#     rm $EXTRACOMPONENTS_FILE > /dev/null 2>&1
# fi