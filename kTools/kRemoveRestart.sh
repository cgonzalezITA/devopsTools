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
NAMESPACEDESC="in default namespace."
NAMESPACEARG=""
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
# \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# FOLDER_ARTIFACTS=./KArtifacts/
COMMAND=delete
COMMANDSAVAILABLE=" d delete r restart "
# \t-a <artifact>: used to access no standard kubernete artifacts (challenges, clusterissuer, ...)      \n
K8SARTIFACT=""
ARTIFACTSFULLNAMES=" all pod pods svc service services deploy deployment deployments statefulset statefulsets ingress ingresses cm configmap configmaps secret secrets job jobs networkpolicy networkpolicies pvc persistentvolumeclaim pv persistentvolume ns namespace "
# \t-fs: Force process  match the given clue (using this, the clue is not a clue, but the name)       \n
USECCLUE=true
CCLUE=""

#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <component clue> [<k8s artifact>:pod*|service|challenge|ingres|...]  \n
            \t-h: Show help info                                                                                         \n
            \t-a <artifact>: used to access no standard kubernete artifacts (challenges, clusterissuer, ...)             \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)                   \n
            \t-fnv: Force namespace name match the given clue (using this, the clue is not a clue, but the name)         \n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used.                                          \n
            \t                    export DEF_KTOOLS_NAMESPACE=<NSCLUE> env var to avoid having to repeat it on kTools commands    \n
            \t-nd: Shortcut for -n default                                                                               \n
            \t-c <command>: Operation to be run on the artifact [delete*|r|restart (rollout restart)]                    \n
            \t-v: Do not show verbose info                                                                               \n
            \t<component clue>: Clue to identify the artifact file name                                                  \n
            \t[<k8s artifact>]: k8s Artifact type to be deleted about (pod*, pvc, ...)\n"
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
        # -f ) 
        #     FOLDER_ARTIFACTS=$2
        #     if ! test -d $FOLDER_ARTIFACTS;then echo -e $(help "ERROR: Folder [$FOLDER_ARTIFACTS] must exist");return -1; fi;
        #     shift ; shift ;;
        -fv|--forcevalue) 
            USECCLUE=false; shift ;;
        -c | --command ) 
            COMMAND="$2"
            shift ; shift ;;
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; shift ;;
        -a | --artifact ) 
            K8SARTIFACT=$2            
            shift ; shift ;;
        -n | --namespace ) 
            # echo analyzing ns=$2;
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
                # CCLUE deploy/opa will be split into CCLUE=opa and K8SARTIFACT=deploy
                if [[ "$1" == *"/"* ]]; then
                    # Split the input into V1 and V2
                    K8SARTIFACT=$(echo "$1" | cut -d'/' -f1)
                    CCLUE=$(echo "$1" | cut -d'/' -f2)
                else
                    CCLUE=$1
                fi
                CCLUEORIG=$CCLUE
                shift;
            elif test "${#K8SARTIFACT}" -eq 0; then
                K8SARTIFACT=$1;
                shift;
            fi ;;
    esac
done

if test "${#CCLUE}" -eq 0; then
    echo -e $(help "ERROR: <k8s componet name clue> is mandatory")
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
elif test "${#K8SARTIFACT}" -eq 0; then
    K8SARTIFACT="pod"
elif [[ ! ${ARTIFACTSFULLNAMES[@]} =~ " $K8SARTIFACT " ]];  then
    # Swapping is done between K8SARTIFACT AND CCLUE
    TMP=$CCLUE
    CCLUE=$K8SARTIFACT
    K8SARTIFACT=$TMP
    if [[ ! ${ARTIFACTSFULLNAMES[@]} =~ " $K8SARTIFACT " ]];  then
        TMP=$K8SARTIFACT
        K8SARTIFACT=$CCLUE
        CCLUE=$TMP
    fi
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


if [[ ! ${COMMANDSAVAILABLE[@]} =~ " $COMMAND " ]]; then
    echo -e $(help "# ERROR: <command> must be one of [$COMMANDSAVAILABLE]");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
elif [[ $COMMAND =~ ^(r|restart)$ ]]; then 
    COMMAND="rollout restart";
elif [[ $COMMAND =~ ^(d|delete)$ ]]; then 
    COMMAND="delete"
fi

getArtifact_result=$( $BASEDIR/_kGetArtifact.sh $K8SARTIFACT "$USECCLUE" "$CCLUE" "$NAMESPACEARG" "$COMMAND" false);
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

if [ "$VERBOSE" = true ]; then
    # echo "  ARTIFACTS_FOLDER=[$FOLDER_ARTIFACTS]"
    echo "---"
    echo "  INFO: EXECUTING COMMAND [$COMMAND] of [$K8SARTIFACT] [$CNAME] $NAMESPACEDESC"
    MSG="[$NSCLUE] -> [$NAMESPACE]"
    if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"; fi
    echo "          NAMESPACE=$MSG" | egrep --color=auto  "$NSCLUE" 
    echo "  K8S_COMPONENTNAME=[$CCLUE] -> [$CNAME]" | egrep --color=auto  "$CCLUE"
    echo "        K8SARTIFACT=[$K8SARTIFACT]"
    echo "            COMMAND=[$COMMAND]"
    echo -e "  Matching [$K8SARTIFACT]:\n$( kubectl get $NAMESPACEARG $K8SARTIFACT $CNAME)"
fi
MSG="QUESTION: [$COMMAND] [$K8SARTIFACT] [$CNAME] $NAMESPACEDESC?"
echo "---"
read -p "$MSG. Are you sure [Y/n]? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[1Yy]$ ]]; then
    PVNAME=""
    if [ "$K8SARTIFACT" == "pvc" ]; then 
        getArtifact_result=$( $BASEDIR/_kGetArtifact.sh $K8SARTIFACT false "$CNAME" "$NAMESPACEARG" "$COMMAND" false ":spec.volumeName");
        RC=$?; 
        if test "$RC" -ne 0; then 
            echo -e $(help "  ERROR: $getArtifact_result");
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
        elif test "${#getArtifact_result}" -eq 0; then
            # Selected not to use the artifacts
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
        else    
            PVNAME=$getArtifact_result;
        fi
    fi

    CMD="kubectl $COMMAND $NAMESPACEARG $K8SARTIFACT $CNAME"
    echo "  Running command [${CMD}]"
    echo "---"
    PVDETAILS=$( kubectl get pv $PVNAME)
    bash -c "$CMD"
    if test "${#PVNAME}" -gt 0; then
        echo "  Deleted [$K8SARTIFACT] is bound to a [pv] [$PVNAME]."
        echo -e "$PVDETAILS"
        read -p "  Do you want to delete it. Are you sure [Y/n]? " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            CMD="kubectl $COMMAND pv $PVNAME"
            echo -e "\n  Running command [${CMD}]"
            echo "---"
            bash -c "$CMD"
        fi
    fi
fi
