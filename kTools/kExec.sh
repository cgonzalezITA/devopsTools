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
NAMESPACE=""
NAMESPACEDESC="in default namespace."
NAMESPACEARG=""
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# \t-c <container name>: Container inside the pod target of the command.                                \n
CARG=""
CCOMPONENT=""
# \t-fv: Force secretname match the given clue (using this, the clue is not a clue, but the name)       \n
USECCLUE=true
K8SARTIFACT=pods
# \t<k8s componet name clue>: Clue to identify the artifact file name                                   \n
CCLUE=""
# \t<command>: Command to be executed inside the pod"
COMMAND=""

#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <k8s componet name clue> [-- <command:def: sh>]                   \n 
            \t-h: Show help info                                                                                   \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)             \n
            \t-fnv: Force namespace name match the given clue (using this, the clue is not a clue, but the name)   \n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used.                                    \n
            \t                    export DEF_KTOOLS_NAMESPACE=<NSCLUE> env var to avoid having to repeat it on kTools commands \n
            \t-nd: Shortcut for -n default                                                                             \n
            \t-v: Do not show verbose info                                                                         \n
            \t-c <container name>: Container inside the pod to be used.                                            \n
            \t\t (used when several containers are deployed during pod initialization. eg. initContainers)         \n
            \t<k8s componet name clue>: Clue to identify the artifact file name                                    \n
	    \t<command>: Command to be executed inside the pod (def /bin/bash)"
    echo $HELP
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
            # echo "help rc=$?"
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            break ;;
        -fv | --forcevalue ) 
            USECCLUE=false; shift ;;
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; shift ;;
        -n | --namespace ) 
            NSCLUE=$2
            shift ; shift ;;
        -c | --container ) 
            CCOMPONENT=$2
            CARG="-c $CCOMPONENT"
            shift ; shift ;;
        -nd | --namespace-default ) 
            NAMESPACESET=true
            NSCLUE="default"
            shift ;;
        * ) 
            if [[ $1 == -* && $1 != --* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#CCLUE}" -eq 0; then
                CCLUE=$1
                shift;
            elif [[ $1 == --* ]]; then                 
                COMMAND=${1:2};
                shift;
                [[ "$#" -eq 0 ]] && break;
                COMMAND="$COMMAND $@"
                break;
            fi ;;
    esac
done


if test "${#CCLUE}" -eq 0; then
    echo -e $(help "ERROR: <k8s componet name clue> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif test "${#COMMAND}" -eq 0; then
    COMMAND="/bin/bash"
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
    NAMESPACEDESC="in namespace [$NAMESPACE]"; 
    NAMESPACEARG="-n $NAMESPACE"; 
fi

# Code

shopt -s expand_aliases
. ~/.bash_aliases
getArtifact_result=$( _kGetArtifact $K8SARTIFACT "$USECCLUE" "$CCLUE" "$NAMESPACEARG" "exec in pod" false);
RC=$?; 
if test "$RC" -ne 0; then 
    echo -e $(help "  ERROR: $getArtifact_result");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif test "${#getArtifact_result}" -eq 0; then
    # Selected not to use the artifacts
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
else    
    CNAME=$getArtifact_result;
fi


CMD="kubectl exec -it $NAMESPACEARG $CNAME $CARG -- $COMMAND"
if [ "$VERBOSE" = true ]; then
    echo "---"
    echo "INFO: EXECUTING COMMAND [$COMMAND] inside [$K8SARTIFACT] [$CNAME] $NAMESPACEDESC"
    MSG="[$NSCLUE] -> [$NAMESPACE]"
    if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then
        MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"
    fi
    echo "  NAMESPACE=$MSG" | egrep --color=auto  "$NSCLUE" 
    echo "  CNAME    =[$CCLUE] -> [$CNAME]" | egrep --color=auto  "$CCLUE"
    echo "  COMMAND  =[$COMMAND]"
    echo "  COMPONENT=[${CCOMPONENT}]"
    echo -e "  CONTAINERS IN POD [$CNAME]:     $(kubectl get $NAMESPACEARG $K8SARTIFACT $CNAME -o jsonpath='{.spec.containers[*].name}')" | egrep --color=auto  "$CCOMPONENT"
    echo -e "  INITCONTAINERS IN POD [$CNAME]: $(kubectl get $NAMESPACEARG $K8SARTIFACT $CNAME -o jsonpath='{.spec.initContainers[*].name}')" | egrep --color=auto  "$CCOMPONENT"
    echo "  Running command [${CMD}]"
    echo "---"
fi

bash -c "$CMD"
RC=$?; 
if test "$RC" -eq 126; then 
    if [[ "$COMMAND" =~ (bash)$ ]]; then
        echo "---"
        MSG="ERROR: Error running command [$COMMAND] (RC=$RC)"
        COMMAND="/bin/sh"
        read -p "$MSG. Do you want to try [$COMMAND] instead? ('y/n')" -n 1 -r
        echo "";
        if [[ $REPLY =~ ^[Y|y]$ ]]; then 
            CMD="kubectl exec -it $NAMESPACEARG $CNAME $CARG -- \"$COMMAND\""
            echo "  Running command [${CMD}]"
            echo "---"
            bash -c "$CMD"
        fi
    else
        echo "ERROR: Error running command [$COMMAND] (RC=$RC)"
    fi
fi;
