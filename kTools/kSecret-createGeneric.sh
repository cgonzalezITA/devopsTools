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
ASK=true
FOLDER_ARTIFACTS=./KArtifacts/
COMMAND=apply
CCLUE=""
SECTION="data"
# \t-r: Replaces existing                                                                               \n
REPLACE=false
USEBASE64=true
K8SARTIFACT=secret
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <secret name> <jsonWithData>                                   \n 
            \t-h: Show help info                                                                                   \n
            \t-r: Replaces existing                                                                                \n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used.                                    \n
            \t                    export DEF_KTOOLS_NAMESPACE=<NSCLUE> env var to avoid having to repeat it on kTools commands \n
            \t-nd: Shortcut for -n default                                                                             \n
            \t<secret name>: Name of the secret to be created                                                      \n
            \t<<jsonWithData>: JSON with key-value pairs. It must have the following syntax '{\"key\": \"value\"}'"
    echo $HELP
}

##############################
## Main code                ##
##############################

# getopts arguments
while true; do
    case "$1" in
        # -v) 
        #     VERBOSE=false; shift ;;
        # -y) 
        #     ASK=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
            return 0;
            break ;;
        # -f ) 
        #     FOLDER_ARTIFACTS=$2
        #     if ! test -d $FOLDER_ARTIFACTS;then echo -e $(help "ERROR: Folder [$FOLDER_ARTIFACTS] must exist");return -1; fi;
        #     shift ; shift ;;
        # -fv|--forcevalue) 
        #     USECCLUE=false; shift ;;
        -r) 
            REPLACE=true; shift ;;
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
            fi
            break ;;
    esac
done

if test "$#" -lt 2; then
    echo -e $(help "ERROR: <secretName> & <jsonWithData> are mandatory")
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
SECRETNAME=$1
shift;
JSON=$1

#Namespace management
if test "${#NSCLUE}" -eq 0 && test "${#DEF_KTOOLS_NAMESPACE}" -gt 0; then
    NSCLUE=$DEF_KTOOLS_NAMESPACE
    DEF_KTOOLS_NAMESPACE_USED=true
fi
if test "$NAMESPACEARG" == "--all-namespaces" && test "${#NSCLUE}" -gt 0 ; then
  echo -e $(help "ERROR: -A (--all-namespaces) and -n (specific namespace) are exclusive"); 
  [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
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

# ### Using from-literal #####
# https://unix.stackexchange.com/questions/734915/get-key-and-value-from-json-in-array-with-check
# https://jqplay.org/
    # ENTRIES=$(echo $JSON | jq --raw-output 'to_entries | map(select(.key != null))[] | ("--from-literal="+.key+"=\"" + .value + "\" ")' )
    # RC=$?
    # if test "$RC" -ne 0; then 
    #     echo "ENTRIES=$ENTRIES;RC=$RC"   
    #     [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    # fi
    # readarray -t LITERALARR < <(echo $JSON | jq --raw-output 'to_entries | map(select(.key != null))[] | ("--from-literal="+.key+"=\""+.value+"\" ")')
    # LITERALARR=${LITERALARR[@]}
# ### Using from-file #####
# FROMFILEARG=$(echo '--from-env-file <(jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" /tmp/tmp.json)')
ENTRIES=$(echo $JSON | jq --raw-output 'to_entries | map(select(.key != null))[] | ("\(.key)=\(.value|tostring)\\n")')
TMPFILE="${TMPDIR-/tmp}//$(date +%Y%m%d_%H%M%S).env"
echo -e $ENTRIES > $TMPFILE
# [ "$CALLMODE" == "executed" ] && exit -1 || return -1;



if [ "$VERBOSE" = true ]; then
  MSG="[$NSCLUE] -> [$NAMESPACE]"
  if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"; fi
  echo "             NAMESPACE=$MSG" | egrep --color=auto  "$NSCLUE" 
  echo "              REPLACE?=[$REPLACE]"
  echo "        K8S_SECRETNAME=[$SECRETNAME]"
  echo "  BASE64 encoding used=[$USEBASE64]"
  echo "               SECRETS=[$LITERALARR]"
fi

if [ "$REPLACE" = true ]; then
    artifact=secret
    USECCLUE=false
    CCLUE=$SECRETNAME
    COMMAND=delete
    shopt -s expand_aliases
    . ~/.bash_aliases
    getArtifact_result=$( _kGetArtifact "$artifact" "$USECCLUE" "$CCLUE" "$NAMESPACEARG" "$COMMAND" false);
    # echo "getArtifact_result=$getArtifact_result"
    RC=$?; 
    if test "$RC" -eq 0; then 
        if test "${#getArtifact_result}" -gt 0; then
            item=$getArtifact_result;
            echo -e "---\n  Deleting [$artifact] $item...";
            CMD=$(echo "kubectl delete secret $NAMESPACEARG $SECRETNAME")
            echo "  Running command [$CMD]"
            $CMD
        fi
    fi    
fi
echo "---"
# CMD=$(echo "kubectl create secret generic $NAMESPACEARG $SECRETNAME $LITERALARR")
CMD=$(echo "kubectl create secret generic $NAMESPACEARG $SECRETNAME --from-env-file $TMPFILE")
echo "  Running command [$CMD]"
ERR1=$( $CMD  2>&1)
RC=$?
if test "$RC" -ne 0; then 
    echo -e $(help "Error creating secret $SECRETNAME: $ERR1")
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
else
    echo "---"
    kubectl get secret $NAMESPACEARG $SECRETNAME -o json
fi
rm $TMPFILE