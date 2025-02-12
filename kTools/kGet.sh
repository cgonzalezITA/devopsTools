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
# \t[-ans|--all-namespaces]: Search artifacts in all namespaces \n
# \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# FOLDER_ARTIFACTS=./KArtifacts/
COMMAND=get
# \t-a <artifact>: used to access no standard kubernete artifacts (challenges, clusterissuer, ...)      \n
K8SARTIFACT=""
# \t-fs: Force process match the given clue (using this, the clue is not a clue, but the name)       \n
CCLUE=""
USECCLUE=true
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
ARTIFACTS="pod svc deployment statefulset ingress configmap job networkpolicy pvc"
ARTIFACTSFULLNAMES=" all pod pods svc service services deploy deployment deployments statefulset statefulsets ingress ingresses cm configmap configmaps secret secrets job jobs networkpolicy networkpolicies pvc persistentvolumeclaim pv persistentvolume ns namespace "
OUTPUTFORMATS=" yaml json wide "
# \t-o <outputFormat>: One of [$OUTPUTFORMATS] \n
OUTPUTFORMAT=""
# \t[-y|--yes]: No confirmation questions are asked \n
ASK=true
# \t[-w|--watch]: Watch the command using the watch tool: watch <cmd> \n
WATCH=false
# [-ans | --all-namespaces) 

#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] [<k8s artifact>:pod*|all|service|challenge|ingres|...] [<component clue>] \n 
            \t-h: Show help info                                                                                       \n
            \t-a <artifact>: used to access no standard kubernete artifacts (challenges, clusterissuer, ...)           \n
            \t[-y|--yes]: No confirmation questions are asked \n
            \t-fnv: Force namespace name match the given clue (using this, the clue is not a clue, but the name)       \n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used.                                        \n
            \t                    export DEF_KTOOLS_NAMESPACE=<NSCLUE> env var to avoid having to repeat it on kTools commands  \n
            \t-nd: Shortcut for -n default                                                                             \n
            \t- [-ans|--all-namespaces]: Search artifacts in all namespaces \n
            \t-v: Do not show verbose info                                                                             \n
            \t-o <outputFormat>: One of [$OUTPUTFORMATS] \n
            \t-fv: Force component's name match the given component's clue (using this, the clue is not a clue, but the name). It makes sense when using -o yaml|json option \n
            \t[-w|--watch]: Watch the command using the watch tool: watch <cmd> \n
            \t[<component clue>]: Clue to identify the artifact file name|all                                          \n
            \t[<k8s artifact>]: k8s Artifact to show info about. Values: pod*, all, svc, ...                           \n
            \n[<component clue>] and [<k8s artifact>] can in some context be swapped to match existing artifacts"
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
        -w | --watch )
            WATCH=true; shift ;;
        -y | --yes ) 
            ASK=false; shift ;;
        -o | --output)
            # \t-o <outputFormat>: One of [$OUTPUTFORMATS] \n
            OUTPUTFORMAT="-o $2"
            shift ; shift ;;
        -fv|--forcevalue) 
            USECCLUE=false; shift ;;
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; shift ;;
        -a | --artifact ) 
            K8SARTIFACT=$2            
            shift ; shift ;;
        -ans | --all-namespaces) 
            NAMESPACEARG="--all-namespaces"
            NAMESPACE="--all-namespaces"
            NAMESPACEDESC="in all-namespaces"
            shift ;;
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
            elif test "${#K8SARTIFACT}" -eq 0; then
                K8SARTIFACT=$1;
            fi ;
            shift ;;
    esac
done


if test "${#CCLUE}" -eq 0; then
    CCLUE=""
    CCLUEEMPTY=true
else
    CCLUEEMPTY=false
    if test "${#K8SARTIFACT}" -eq 0 && [[ ${ARTIFACTSFULLNAMES[@]} =~ " $CCLUE " ]];  then
        if [ "$VERBOSE" = true ]; then
            echo "# NOTE: CCLUE [$CCLUE] matches a k8s artifact name. To use [$CCLUE] as a clue for the component's name use syntax -a <k8sArtifact> $CCLUE"
        fi
        K8SARTIFACT=$CCLUE
        CCLUE=""
    fi
fi

if test "${#K8SARTIFACT}" -eq 0; then
    K8SARTIFACT="pod"
elif [[ ! ${ARTIFACTSFULLNAMES[@]} =~ " $K8SARTIFACT " ]] &&[[ "$CCLUEEMPTY" == false ]] ;  then
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
if ! test "$NAMESPACEARG" == "--all-namespaces" && test "${#NSCLUE}" -eq 0 && test "${#DEF_KTOOLS_NAMESPACE}" -gt 0; then
    NSCLUE=$DEF_KTOOLS_NAMESPACE
    DEF_KTOOLS_NAMESPACE_USED=true
fi
if test "$NAMESPACEARG" == "--all-namespaces"; then
    if test "${#NSCLUE}" -gt 0 ; then
        echo -e $(help "ERROR: -ans (--all-namespaces) and -n (specific namespace) are exclusive"); 
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    elif [[ "$OUTPUTFORMAT" =~ ^(-o yaml|-o json)$ ]]; then
        echo -e $(help "ERROR: -ans (--all-namespaces) and $OUTPUTFORMAT are exclusive"); 
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    fi
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

# From here, $K8SARTIFACT != all for sure
if  [ "${#CCLUE}" -eq 0 ] && [[ "$OUTPUTFORMAT" =~ ^(-o yaml|-o json)$ ]]; then
    echo -e $(help "  ERROR: -o option [$OUTPUTFORMAT] requires a k8s component's name'. None was given");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif [ "${#CCLUE}" -eq 0 ]; then
    GREPCMD=""
    GREPK8SCMD=""
    PATTERNDESC=""
    PATTERN4COMMAND=$PATTERNDESC
elif [[ "$OUTPUTFORMAT" =~ ^(-o yaml|-o json)$ ]]; then
    getArtifact_result=$( $BASEDIR/_kGetArtifact.sh $K8SARTIFACT "$USECCLUE" "$CCLUE" "$NAMESPACEARG" "get a k8s [$K8SARTIFACT]" false )
    RC=$?; 
    if test "$RC" -ne 0; then 
        echo -e $(help "  ERROR: $getArtifact_result");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    elif test "${#getArtifact_result}" -eq 0; then
        echo -e $(help "  ERROR: -o option [$OUTPUTFORMAT] requires a k8s component's name. None was given");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    else    
        PATTERNDESC=$getArtifact_result;
        PATTERN4COMMAND=$PATTERNDESC
        GREPCMD="| grep $CCLUE"
        [ "$WATCH" = false ] && GREPCMD="$GREPCMD | egrep --color=auto  '$CCLUE|$'"
        GREPK8SCMD=""
    fi    
else
    GREPCMD="| grep $CCLUE"
    [ "$WATCH" = false ] && GREPCMD="$GREPCMD | egrep --color=auto  '$CCLUE|$'"
    GREPK8SCMD=$GREPCMD
    PATTERNDESC="[*$CCLUE*]"
    PATTERN4COMMAND=""
fi

if ! test "${#OUTPUTFORMAT}" -eq 0; then
    # For get commands with -o an k8s artifact has to be provided
    CMD="kubectl $COMMAND $K8SARTIFACT $PATTERN4COMMAND $NAMESPACEARG $OUTPUTFORMAT $GREPK8SCMD"
else
    CMD="kubectl $COMMAND $K8SARTIFACT  $NAMESPACEARG $OUTPUTFORMAT $GREPK8SCMD"
fi
if [ "$WATCH" = true ]; then
    CMD="watch \"$CMD"\"
fi

if [ "$VERBOSE" = true ]; then
    MSG="[$NSCLUE] -> [$NAMESPACE]"
    if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"; fi
    echo -e "# NAMESPACE=$MSG" | egrep --color=auto  $NSCLUE
    echo "# K8SARTIFACT=[$K8SARTIFACT]"| egrep --color=auto  $K8SARTIFACT
    CMD1="echo -e  '# K8S_COMPONENTNAME=[$CCLUE]->$PATTERNDESC' $GREPCMD"
    bash -c "$CMD1"
    echo "# COMMAND=[$COMMAND]"
    if ! test "${#OUTPUTFORMAT}" -eq 0; then
        echo "# OUTPUT=[$OUTPUTFORMAT]"
    fi
    echo "VERBOSE=[$ASK]" 
    echo "WATCH=[$WATCH]"
    echo "#   Running command [$CMD]"
fi


if  [ "$K8SARTIFACT" == "all" ]; then
    # Gets all k8s artifacts. As shown in https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
    item=$CCLUE
    for artifact in $ARTIFACTS; do
        echo "---"
        if [ "$ASK" = true ]; then
            read -p "  Showing [$artifact] '*$item*' $NAMESPACEDESC: (press a key to continue)" -n 1 -r
            echo "";
        fi
        $SCRIPTNAME -fnv $NAMESPACEARG -a $artifact -fv $item -v -y
    done
    echo ""
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
else
    [ ${#CCLUE} -gt 0 ] && CLUEDESC="'*$CCLUE*' " || CLUEDESC="";
    [ "$VERBOSE" == true ] &&echo -e "---\n# Showing $K8SARTIFACT $CLUEDESC$NAMESPACEDESC" | egrep --color=auto  $K8SARTIFACT;
    [ "$WATCH" == true ] && sleep 1;
    eval $CMD
fi
