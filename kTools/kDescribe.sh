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
# \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# \t-sc: Show only container names                                                                       \n
SHOWONLYCONTAINERS=false
# FOLDER_ARTIFACTS=./KArtifacts/
COMMAND=describe
CCLUE=""
# \t-fs: Force secretname match the given clue (using this, the clue is not a clue, but the name)       \n
USECCLUE=true
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
# \t-c <container name>: Container inside the pod target of the command.                                \n
CARG=""
CCOMPONENT=""
ARTIFACTSFULLNAMES=" all pod pods svc service services deploy deployment deployments statefulset statefulsets ingress ingresses cm configmap configmaps secret secrets job jobs networkpolicy networkpolicies pvc persistentvolumeclaim pv persistentvolume storageclass cronjob "
# \t-a <artifact>: used to access no standard kubernete artifacts (challenges, clusterissuer, ...)           \n
K8SARTIFACT=""
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <component clue> [<k8s artifact>:pod*|all|service|challenge|ingres|...] \n 
            \t-h: Show help info                                                                                     \n
            \t-a <artifact>: used to access no standard kubernete artifacts (challenges, clusterissuer, ...)         \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)               \n
            \t-fnv: Force namespace name match the given clue (using this, the clue is not a clue, but the name)     \n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used.                                      \n
            \t                    export DEF_KTOOLS_NAMESPACE=<NSCLUE> env var to avoid having to repeat it on kTools commands   \n
            \t-nd: Shortcut for -n default                                                                             \n
            \t-c <container name>: Container inside the pod to be used.                                              \n
            \t-v: Do not show verbose info                                                                           \n
            \t-sc: Show only container names                                                                          \n
            \t<component clue>: Clue to identify the artifact file name                                              \n
            \t[<k8s artifact>]: k8s Artifact to show info about. Values: pod*, all, svc, ..."
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
        -sc) 
            # \t-sc: Show only container names                                                                       \n
            SHOWONLYCONTAINERS=true; shift ;;
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
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; shift ;;
        -c | --container ) 
            CCOMPONENT=$2
            CARG="-c $COMPONENT"
            shift ; shift ;;
        -a | --artifact ) 
            K8SARTIFACT=$2            
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
                # CCLUE deploy/opa will be split into CCLUE=opa and K8SARTIFACT=deploy
                if [[ "$1" == *"/"* ]]; then
                    # Split the input into V1 and V2
                    K8SARTIFACT=$(echo "$1" | cut -d'/' -f1)
                    CCLUE=$(echo "$1" | cut -d'/' -f2)
                else
                    CCLUE=$1
                fi
                CCLUEORIG=$CCLUE;
            elif test "${#K8SARTIFACT}" -eq 0; then
                K8SARTIFACT=$1;
            fi ;
            shift ;;
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

if  [ "$K8SARTIFACT" == "all" ]; then
    # Describes all k8s artifacts. As shown in https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
    echo "Describing artifacts matching the clue [$CCLUE]..."
    for artifact in pod svc deployment statefulset configmap networkpolicy; do
        echo -e "\n ------------------------\n Describing [$artifact] matching the clue [$CCLUE]..."
        # getArtifact $artifact true
        getArtifact_result=$( kGetArtifact "$artifact" "$USECCLUE" "$CCLUE" "$NAMESPACEARG" "$COMMAND" true);
        RC=$?; 
        if test "$RC" -ne 0; then 
            echo -e $(help "  WARNING: \$getArtifact_result");
            continue;
        elif test "${#getArtifact_result}" -eq 0; then
            # Selected not to use the artifacts
            continue;
        else    
            item=$getArtifact_result;
            echo -e "\n  Showing description of [$artifact] $item:";
            $SCRIPTNAME -fnv $NAMESPACEARG $CARG -fv $item $artifact
        fi
    done
    echo ""
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if [ "$USECCLUE" = true ]; then
    CNAME=$(kubectl get $K8SARTIFACT $NAMESPACEARG --no-headers -o custom-columns=":metadata.name" | tac | grep $CCLUE)
else
    CNAME=$CCLUE
fi

# if test "${#CNAME}" -eq 0; then
#     echo -e $(help "ERROR: No [$K8SARTIFACT] with clue [$CCLUE] has been found $NAMESPACEDESC");
#     [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
# else
#     NLINES=$(echo "$CNAME" | wc -l)
#     if test "$NLINES" -ne 1; then
#         echo -e $(help "ERROR: [$K8SARTIFACT] clue [$CCLUE] is too generic. [$NLINES] matches have been found: [$CNAME]")
#         kubectl get $K8SARTIFACT $NAMESPACEARG | grep $CCLUE
#         [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
#     fi
# fi

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


CMD="kubectl $COMMAND $NAMESPACEARG $K8SARTIFACT $CGARG $CNAME"
if [ "$VERBOSE" = true ]; then
    MSG="[$NSCLUE] -> [$NAMESPACE]"
    if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then
        MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"
    fi
    echo "          NAMESPACE=$MSG" | egrep --color=auto  "$NSCLUE" 
    echo "        K8SARTIFACT=[$K8SARTIFACT]"
    echo "  K8S_COMPONENTNAME=[$CCLUE] -> [$CNAME]" | egrep --color=auto  "$CCLUE"
    echo "          COMPONENT=[${CCOMPONENT}]"
    echo "            COMMAND=[$COMMAND]"
    if [[ "$K8SARTIFACT" =~ ^(pods?)$ ]]; then
        echo -e "  CONTAINERS IN POD [$CNAME]:     $(kubectl get $NAMESPACEARG $K8SARTIFACT $CNAME -o jsonpath='{.spec.containers[*].name}')" | egrep --color=auto  "$CCOMPONENT"
        echo -e "  INITCONTAINERS IN POD [$CNAME]: $(kubectl get $NAMESPACEARG $K8SARTIFACT $CNAME -o jsonpath='{.spec.initContainers[*].name}')\n" | egrep --color=auto  "$CCOMPONENT"
        if [ "$SHOWONLYCONTAINERS" = true ]; then
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
        fi
    fi
    echo "  INFO: Getting description of [$K8SARTIFACT] [$CNAME] $NAMESPACEDESC"
    echo "---"
    echo "  Running command [${CMD}]"
fi
bash -c "$CMD"