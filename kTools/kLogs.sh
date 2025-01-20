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
# \t-ac | --all-containers: Mimics the --all-containers=true kubectl argument \n
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
# t[-y|--yes]: No confirmation questions are asked \n
ASK=true
# \t[-o|--output] <outputFile>: Writes the content into the <outputFile> (-y flag is set)\n
OUTPUTFILE=""

#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <component clue>                                                                \n 
            \t-h: Show help info                                                                                                    \n
            \t[-y|--yes]: No confirmation questions are asked \n
            \t[-o|--output] <outputFile>: Writes the content into the <outputFile> (-y flag is set)\n
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
        -o | --output )
            # \t[-o|--output] <outputFile>: Writes the content into the <outputFile> (-y flag is set)\n
            OUTPUTFILE=$2
            ASK=false
            echo > ${OUTPUTFILE:-/dev/stdout}
            shift ; shift ;;
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
        -ac | --all-containers )
            # : Mimics the --all-containers=true kubectl argument \n
            CARG="--all-containers"
            shift ;;
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
    echo "INFO: Showing logs of [$K8SARTIFACT] [$CNAME] (and all its initContainers) $NAMESPACEDESC" >> ${OUTPUTFILE:-/dev/stdout}; 
    MSG="[$NSCLUE] -> [$NAMESPACE]"
    if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then
        MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"
    fi
    echo "NAMESPACE=$MSG" >> ${OUTPUTFILE:-/dev/stdout} | egrep --color=auto  "$NSCLUE" 
    echo "K8SARTIFACT=[$K8SARTIFACT]" >> ${OUTPUTFILE:-/dev/stdout}
    echo "K8S_COMPONENTNAME=[$CCLUE] -> [$CNAME]" >> ${OUTPUTFILE:-/dev/stdout} | egrep --color=auto  "$CCLUE"
    echo "SINCE=[${SINCEARG}]" >> ${OUTPUTFILE:-/dev/stdout}
    echo "STRING2EXCLUDE=$JSON2EXCLUDE" >> ${OUTPUTFILE:-/dev/stdout}
    if test "${#PODCONTAINERS}" -gt 0; then
        echo -e "CONTAINERS IN [$K8SARTIFACT] [$CNAME]:     $PODCONTAINERS" >> ${OUTPUTFILE:-/dev/stdout} | egrep --color=auto  "$CCOMPONENT"
        echo -e "INITCONTAINERS IN [$K8SARTIFACT] [$CNAME]: $PODINITCONTAINERS" >> ${OUTPUTFILE:-/dev/stdout} | egrep --color=auto  "$CCOMPONENT"
    fi
    [ "$CARG" == "all-containers" ] && echo "--all-containers=true"
fi

function run() {
    if test "$#" -ge 1; then
        [ "$1" == "--all-containers" ] && CARG1="$1=true" || CARG1="-c $1"; 
    else
        CARG1=""
    fi    
    CMD="kubectl logs $NAMESPACEARG $SINCEARG -f $K8SARTIFACT/$CNAME $CARG1" # $GREPEXCLUDE
    # CMD=${GREPEXCLUDE}${CMD}${GREPEXCLUDECLOSEPARAMS}
    CMD=${CMD}${GREPEXCLUDE}
    MSG="# Running command [${CMD}]"
    if [ "$DOWAIT" = true ]; then
        MSG="$MSG\n    in 3 seconds (or press any key to continue)\n---"
        [ "$VERBOSE" = true ] && echo -e $MSG >> ${OUTPUTFILE:-/dev/stdout};
        read -t 3 -p ""
    else
        [ "$VERBOSE" = true ] && echo -e $MSG >> ${OUTPUTFILE:-/dev/stdout};
    fi
    bash -c "$CMD" >> ${OUTPUTFILE:-/dev/stdout}
}
if test "${#CARG}" -eq 0; then
    if test "${#PODINITCONTAINERS}" -gt 0; then
        for INITCONTAINER in $PODINITCONTAINERS; do
            [ "$VERBOSE" = true ] && echo "---" >> ${OUTPUTFILE:-/dev/stdout};
            if [ "$ASK" = true ]; then
                read -p "    Do you want to view the logs of INIT container '$INITCONTAINER' [Y/n]? " -n 1 -r
                echo > /dev/tty;
            else REPLY="y"; fi
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                run $INITCONTAINER
            fi
        done
        for CONTAINER in $PODCONTAINERS; do
            [ "$VERBOSE" = true ] && echo "---" >> ${OUTPUTFILE:-/dev/stdout};
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
        [ "$VERBOSE" = true ] && echo "---" >> ${OUTPUTFILE:-/dev/stdout};
        run
    fi
else
    [ "$VERBOSE" = true ] && echo "---" >> ${OUTPUTFILE:-/dev/stdout};
    run $CARG
fi
