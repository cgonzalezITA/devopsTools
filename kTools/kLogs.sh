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
# \t!v: Do not show verbose info                                                                        \n
VERBOSE=true
# \t[<k8s artifact>]: k8s Artifact to show info about"
CCLUE=""
# \t-fs: Force process match the given clue (using this, the clue is not a clue, but the name)       \n
USECCLUE=true
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
K8SARTIFACT=""
K8SDEPLOYNAMES=" d deploy deployment deployments "
ARTIFACTSFULLNAMES=" pod pods svc service services $K8SDEPLOYNAMES  "
# \t-c <container name>: Container inside the artifact target of the command.                           \n
# CARG="--all-containers --max-log-requests 20"
CARG=""
CCOMPONENT=""
# \t-s <sinceTime>: Show logs generated since <sinceTime> moment. eg: 0s, 5s, 5m, 1h, ...               \n
SINCEARG=""
# \t-x \"<jsonArrayWithStrings2Exclude>\": Exclude lines containing any of the given strings            \n
GREPEXCLUDE=""
# GREPEXCLUDECLOSEPARAMS=""
# \t-w: wait (3 seconds wait before running the command)                                                \n
DOWAIT=false
# \t-y: No confirmation questions are asked                                                             \n
ASK=true
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <component clue>                                                                \n 
            \t-h: Show help info                                                                                                    \n
            \t-y: No confirmation questions are asked                                                             \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)                              \n
            \t-c <artifact name>: Container inside the artifact to be used.                                                             \n
            \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)                    \n
            \t-w: wait (3 seconds wait before running the command)                                                                  \n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used.                                                     \n
            \t                    export DEF_KTOOLS_NAMESPACE=<NSCLUE> env var to avoid having to repeat it on kTools commands                  \n
            \t-nd: Shortcut for -n default                                                                             \n
            \t-v: Do not show verbose info                                                                                          \n
            \t-x \"<jsonArrayWithStrings2Exclude>\": Exclude lines containing any of the given strings. Format: '[\"str1\",\"str2\",...]' \n
            \t-s <sinceTime>: Show logs generated since <sinceTime> moment. eg: 0s, 5s, 5m, 1h, ...                                 \n
            \t<component clue>*: Clue to identify the artifact file name"
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
            return 0 ;;
        -y | --yes ) 
            ASK=false; shift ;;
        -fv | --forceValue ) 
            USECCLUE=false; shift ;;
        -s | --since ) 
            SINCEARG="--since $2"
            shift ; shift ;;
        -x | --exclude )
            JSON2EXCLUDE=$2
            echo "Test $JSON2EXCLUDE"
            readarray -t GREPEXCLUDE   < <(echo $JSON2EXCLUDE | jq --raw-output 'map(sub("^";"| grep -v \"")) | map(sub("$";"\"")) | join(" ")')
            echo "Test $JSON2EXCLUDE"
            shift ; shift ;;
        -w | --wait ) 
            DOWAIT=true; shift ;;
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; shift ;;
        -c | --container ) 
            CCOMPONENT=$2
            CARG="$CCOMPONENT"
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
if [ "$K8SARTIFACT" == "pod" ]; then 
    SPECBASE='.spec'
elif [[ ${K8SDEPLOYNAMES[@]} =~ " $K8SARTIFACT " ]];  then
    K8SARTIFACT="deployment"
    SPECBASE='.spec.template.spec'
fi


#Namespace management
if test "${#NSCLUE}" -eq 0 && test "${#DEF_KTOOLS_NAMESPACE}" -gt 0; then
    NSCLUE=$DEF_KTOOLS_NAMESPACE
    DEF_KTOOLS_NAMESPACE_USED=true
fi
if test "${#NSCLUE}" -gt 0; then
    if [ "$USENSCCLUE" = true ]; then
        NAMESPACEORERROR=$( $BASEDIR/_kGetNamespace.sh $NSCLUE );
        # echo "NAMESPACEORERROR=$NSCLUE --> $NAMESPACEORERROR"
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

getArtifact_result=$( $BASEDIR/_kGetArtifact.sh $K8SARTIFACT "$USECCLUE" "$CCLUE" "$NAMESPACEARG" "show logs" false);
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

CMD="kubectl get $NAMESPACEARG $K8SARTIFACT $CNAME -o jsonpath='{$SPECBASE.containers[*].name}'"
PODCONTAINERS=$(eval "$CMD")
CMD="kubectl get $NAMESPACEARG $K8SARTIFACT $CNAME -o jsonpath='{$SPECBASE.initContainers[*].name}'"
PODINITCONTAINERS=$(eval "$CMD")

if [ "$VERBOSE" = true ]; then
    echo "---"
    echo "INFO: Showing logs of [$K8SARTIFACT] [$CNAME] (and all its initContainers) $NAMESPACEDESC"
    MSG="[$NSCLUE] -> [$NAMESPACE]"
    if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then
        MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"
    fi
    echo "NAMESPACE=$MSG" | egrep --color=auto  "$NSCLUE" 
    echo "K8SARTIFACT=[$K8SARTIFACT]"
    echo "K8S_COMPONENTNAME=[$CCLUE] -> [$CNAME]" | egrep --color=auto  "$CCLUE"
    echo "SINCE=[${SINCEARG}]"
    echo "STRING2EXCLUDE=$JSON2EXCLUDE"
    if test "${#PODCONTAINERS}" -gt 0; then
        echo -e "  CONTAINERS IN [$K8SARTIFACT] [$CNAME]:     $PODCONTAINERS" | egrep --color=auto  "$CCOMPONENT"
        echo -e "  INITCONTAINERS IN [$K8SARTIFACT] [$CNAME]: $PODINITCONTAINERS" | egrep --color=auto  "$CCOMPONENT"
        # echo "  SHOW INFO OF CONTAINER=[${CARG}]"
    fi
fi

function run() {
    if test "$#" -ge 1; then
        CARG1="-c $1"
    else
        CARG1=""
    fi    
    CMD="kubectl logs $NAMESPACEARG $SINCEARG -f $K8SARTIFACT/$CNAME $CARG1" # $GREPEXCLUDE
    # CMD=${GREPEXCLUDE}${CMD}${GREPEXCLUDECLOSEPARAMS}
    CMD=${CMD}${GREPEXCLUDE}
    MSG="# Running command [${CMD}]"
    if [ "$DOWAIT" = true ]; then
        MSG="$MSG\n    in 3 seconds (or press any key to continue)\n---"
        echo -e $MSG
        read -t 3 -p ""
    else
        echo -e $MSG
    fi
    bash -c "$CMD"
}
if test "${#CARG}" -eq 0; then
    if test "${#PODINITCONTAINERS}" -gt 0; then
        for INITCONTAINER in $PODINITCONTAINERS; do
            echo "---"
            if [ "$ASK" = true ]; then
                read -p "    Do you want to view the logs of INIT container '$INITCONTAINER' [Y/n]? " -n 1 -r
                echo > /dev/tty;
            else REPLY="y"; fi
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                run $INITCONTAINER
            fi
        done
        for CONTAINER in $PODCONTAINERS; do
            echo "---"
            REPLY='y'
            if test "${#PODINITCONTAINERS}" -gt 0; then
                if [ "$ASK" = true ]; then
                    read -p "    Do you want to view the logs of CONTAINER '$CONTAINER' [Y/n]? " -n 1 -r
                    echo
                fi
            fi
            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                run $CONTAINER
            fi
        done
    else
        echo "---"
        run
    fi
else
    echo "---"
    run $CARG
fi
