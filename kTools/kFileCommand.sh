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

NSCLUE=""
NAMESPACE="default"
NAMESPACEDESC="in default namespace."
NAMESPACEARG=""
VERBOSE=true
FOLDER_VALUES=./KArtifacts
COMMAND=""
# \t-y: No confirmation questions are asked                                                             \n
ASK=true
# \t-fv: Force secretname match the given clue (using this, the clue is not a clue, but the name)       \n
USECCLUE=true
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
# \t-p <PrefixK8sComponent>: Prefix of the file with the k8s components (def value: k8s_components-*)    \n
FPREFIX="k8s_components"
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <component clue> [<command>:apply*|delete|restart|debug]       \n 
            \t-h: Show help info                                                                                   \n
            \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts) \n
            \t-p <PrefixK8sComponent>: Prefix of the file with the k8s components (def value: k8s_components-*)    \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)             \n
            \t-fnv: Force namespace name match the given clue (using this, the clue is not a clue, but the name)   \n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used.                                    \n
            \t                    export DEF_KTOOLS_NAMESPACE=<NSCLUE> env var to avoid having to repeat it on kTools commands \n
            \t-nd: Shortcut for -n default                                                                             \n
            \t-v: Do not show verbose info                                                                         \n
            \t-y: No confirmation questions are asked                                                             \n
            \t<component clue>: Clue to identify the artifact file name. all to run command on all yaml files      \n
            \t[<command>] Command to be executed against the artifact file: apply*|delete|restart|test"
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
            if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
            break ;;
        -y | --yes ) 
            ASK=false; shift ;;
        -fv | --forcevalue ) 
            USECCLUE=false; shift ;;
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; shift ;;
        -f ) 
            FOLDER_VALUES=$2
            if ! test -d $FOLDER_VALUES;then echo -e $(help "ERROR: Folder [$FOLDER_VALUES] must exist");return -1; fi;
            shift ; shift ;;
        -p )
            FPREFIX=$2
            shift ; shift ;;
        -n | --namespace ) 
            NSCLUE=$2
            shift ; shift ;;
        -nd | --namespace-default ) 
            NAMESPACESET=true
            NSCLUE="default"
            shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#CCLUE}" -eq 0; then
                CCLUE=$1
                shift;
            elif test "${#COMMAND}" -eq 0; then
                COMMAND=$1;
                shift;
            fi ;;
    esac
done

if test "${#CCLUE}" -eq 0; then
    echo -e $(help "ERROR: <component clue> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if [[ "$COMMAND" =~ ^(|up|start|install|u)$ ]]; then
    COMMAND="apply";
elif [[ "$COMMAND" =~ ^(down|stop|del|d)$ ]]; then
    COMMAND="delete";
elif [[ "$COMMAND" =~ ^(r)$ ]]; then
    COMMAND="restart";
elif [[ "$COMMAND" =~ ^(debug)$ ]]; then
    COMMAND="debug";
else
    echo -e $(help "ERROR: Unknown command [$COMMAND]. Valid values are up|start|install|u; down|stop|del|d; r; debug");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi


#Namespace management
if test "${#NSCLUE}" -eq 0 && test "${#DEF_KTOOLS_NAMESPACE}" -gt 0; then
    NSCLUE=$DEF_KTOOLS_NAMESPACE
    DEF_KTOOLS_NAMESPACE_USED=true
fi
if test "${#NSCLUE}" -gt 0; then
    if [ "$USENSCCLUE" = true ]; then
        NAMESPACEORERROR=$( $BASEDIR/_kGetNamespace.sh $NSCLUE );
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

if [[ "$CCLUE" =~ ^(all)$ ]]; then
    # echo "CCLUE=* deploys all the files in the specified folder, so the -f <folder> has to be used"
    USECCLUE=false
    FNAME=$CCLUE
else
    if [ "$USECCLUE" = true ]; then
        FNAME="$FPREFIX-*$CCLUE*"
    else
        FNAME=$CCLUE
    fi

    shopt -s expand_aliases
    . ~/.bash_aliases
    getFileResult=$(_fGetFile "$FOLDER_VALUES" "$USECCLUE" "$FNAME" "$CCLUE" false);
    RC=$?; 
    if test "$RC" -ne 0; then 
        echo -e "  ERROR: $getFileResult";
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    elif test "${#getFileResult}" -eq 0; then
        # Selected not to use the artifacts
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    else    
        FNAME=$getFileResult;
    fi
# if [ "$USECCLUE" = true ]; then
#     FNAME=$(find $FOLDER_VALUES/  -maxdepth 1 -name "$FPREFIX-*$CCLUE*")
# else
#     FNAME=$CCLUE
# fi
fi

if [ "$VERBOSE" = true ]; then
    echo "ARTIFACTS_FOLDER=[$FOLDER_VALUES]"
    MSG="[$NSCLUE] -> [$NAMESPACE]"
    if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"; fi
    echo "NAMESPACE=$MSG" | egrep --color=auto  "$NSCLUE" 
    echo "FILE PREFIX=[$FPREFIX-*]"
    echo "K8S_COMPONENTSFILE=[$CCLUE] -> [$FNAME]" | egrep --color=auto  "$CCLUE"
    echo "COMMAND=[$COMMAND]"
    echo "ASK=[$ASK]" 
fi
if test "${#FNAME}" -eq 0; then
    echo -e $(help "ERROR: No yaml component file has been found in folder [$FOLDER_VALUES] for component clue [$CCLUE]");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
else
    NLINES=$(echo "$FNAME" | wc -l)
    if test "$NLINES" -ne 1; then
        echo -e $(help "ERROR: component clue [$CCLUE] is too generic. [$NLINES] matches have been found in folder [$FOLDER_VALUES]: [$FNAME]");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
fi

if [ "$FNAME" == "all" ]; then
    IDX=1
    CMDF="find $FOLDER_VALUES -name '*.yaml' -o -name '*.yml' -type f"
    NFILES=$( /bin/bash -c "$CMDF | wc -l")
    # echo "NFILES=$NFILES"
    X=""
    for filename in $(/bin/bash -c "$CMDF"); do
        # CMDA="$SCRIPTNAME $NAMESPACEARG -v -f \"\" -fv $filename $COMMAND"
        CMDA="kubectl $COMMAND $NAMESPACEARG -f $filename"
        echo -e "---\nINFO ($IDX/$NFILES): Executing command [$CMDA]"
        IDX=$(($IDX+1))
        X1=$($CMDA 2>&1)
        echo "$X1"
        X="$X\n\t---From file $filename---\n$X1"
    done
    echo -e "---\nSummary:\n$X"
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi


if [ "$COMMAND" == "restart" ]; then
    if [ "$ASK" == true ]; then ASKFLAG=""; else ASKFLAG="-y"; fi
    $SCRIPTNAME $ASKFLAG -v -n $NAMESPACE -f "$FOLDER_VALUES" "$CCLUE" delete
    echo ""
    echo "---"
    sleep 1
    COMMAND=apply
fi

CMD="kubectl $COMMAND $NAMESPACEARG -f \"$FNAME\""
if test "$COMMAND" == "debug"; then
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
if [ "$VERBOSE" = true ]; then
    echo "INFO: Executing kubectl command [$COMMAND] using components from yaml file [$FNAME] $NAMESPACEDESC"
    echo "Running Command [$CMD]"  | egrep --color=auto  "$CCLUE"
    echo "---"
fi
if [ "$ASK" = true ]; then
    MSG="QUESTION: Do you want to run kubectl command [$COMMAND]?"
    read -p "$MSG [Y/n]? " -n 1 -r 
        echo    # (optional) move to a new line
else
    REPLY="y"
fi
if [[ $REPLY =~ ^[1Yy]$ ]]; then
    bash -c "$CMD"
    RC=$?
    if test "$RC" -ne 0; then 
        MSG="ERROR: [$COMMAND] has finished with error (RC=$RC)"
        COMMAND="/bin/sh"
        read -p "$MSG. Do you want to analyze the yaml file? (yamlint must be installed) ('y/n')" -n 1 -r
        echo "";
        if [[ $REPLY =~ ^[Y|y]$ ]]; then 
            CMD="yamllint $FNAME"
            echo "  Running command [${CMD}]"
            echo "---"
            bash -c "$CMD"
        fi
    fi
fi