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
SECTION=""
USECCLUE=true
USEBASE64=true
K8SARTIFACT=secret
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
# \t-f: Field name to be shown (used to just show the field's value without questions) \n
FIELDNAME=""
#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <secret name clue> [section data*]\n 
            \t-h: Show help info\n
            \t-v: Do not show verbose info\n
            \t-y: Skip asking before showing values of each key\n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)\n
            \t-fnv: Force namespace name match the given clue (using this, the clue is not a clue, but the name)\n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used.\n
            \t                    export DEF_KTOOLS_NAMESPACE=<NSCLUE> env var to avoid having to repeat it on kTools commands\n
            \t-nd: Shortcut for -n default\n
            \t-b: Do not show the base64 decrypted value of the keys, just the value as it is in the secret\n
            \t-f: Field name to be shown (used to just show the field's value). -y is automatically set\n
            \t<secret name clue>: Clue to identify the secret to show info about\n
            \t<section>: Section in the secret containing the key-value pairs (data as default)"
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
        -y) 
            ASK=false; shift ;;
        -h | --help ) 
            echo -e $(help);
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            return 0;
            break ;;
        # -f ) 
        #     FOLDER_ARTIFACTS=$2
        #     if ! test -d $FOLDER_ARTIFACTS;then echo -e $(help "ERROR: Folder [$FOLDER_ARTIFACTS] must exist");return -1; fi;
        #     shift ; shift ;;
        -fv|--forcevalue) 
            USECCLUE=false; shift ;;
        -b) 
            USEBASE64=false; shift ;;
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; shift ;;
        -n | --namespace ) 
            # echo analyzing ns=$2;
            NSCLUE=$2
            shift ; shift ;;
        -nd | --namespace-default ) 
            NAMESPACESET=true
            NSCLUE="default"
            shift ;;
        -f | --fieldname )
            # \t-f: Field name to be shown (used to just show the field's value without questions) \n
            FIELDNAME=$2
            ASK=false;
            shift ; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#CCLUE}" -eq 0; then
                CCLUE=$1;
            elif test "${#SECTION}" -eq 0; then
                SECTION=$1;
            fi ;
            shift ;;
    esac
done

if test "${#CCLUE}" -eq 0; then
    echo -e $(help "ERROR: <secret name clue> is mandatory")
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif test "${#SECTION}" -eq 0; then
    SECTION="data"
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

getArtifact_result=$( $BASEDIR/_kGetArtifact.sh $K8SARTIFACT "$USECCLUE" "$CCLUE" "-n $NAMESPACE" "get Secret" false);
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
    echo "---"
    echo "INFO: Getting info of secret [$CNAME] $NAMESPACEDESC"
    MSG="[$NSCLUE] -> [$NAMESPACE]"
    if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then
        MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"
    fi
    echo "NAMESPACE=$MSG" | egrep --color=auto  "$NSCLUE" 
    echo "K8S_SECRETNAME=[$CCLUE] -> [$CNAME]" | egrep --color=auto  "$CCLUE"
    if test ${#FIELDNAME} -gt 0; then
        echo "FIELDNAME=$FIELDNAME"
    fi
    echo "BASE64 encoding used=[$USEBASE64]"
    echo "---"
fi
ITEMS=$( kubectl get $NAMESPACEARG secrets $CNAME -o json | jq --arg v "$SECTION" '.[$v]')
NITEMS=$( echo $ITEMS | jq length)
KEYS=$( echo $ITEMS | jq ' keys | .[]' | tr -d ' ' | tr '\n' ' ' )
KEYS=" $KEYS"
IFS=' '; set -f;
array=( $KEYS )
if test ${#FIELDNAME} -gt 0; then
    if [[ ! ${KEYS[@]} =~ " \"$FIELDNAME\" " ]]; then
        echo -e $(help "  ERROR: Field [$FIELDNAME] not found among the secret's fields [$KEYS]");
    else
        FIELDNAME=$(echo $FIELDNAME | sed 's|\.|\\\.|g')
        CMD="kubectl get $NAMESPACEARG secrets $CNAME -o jsonpath='{.data.$FIELDNAME}' | base64 -d"
        if [ "$VERBOSE" = true ]; then
            echo "Running CMD=[$CMD]"
        fi
        eval $CMD
    fi
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi

if [ "$VERBOSE" = true ]; then 
    echo -e "Found [$NITEMS] field in the section [$SECTION] of the secret [$CNAME]:\n\t[$KEYS]"; fi
IDX=0
for key in "${array[@]}"; do
    IDX=$((++IDX))
    if [ "$ASK" = true ]; then 
        read -p "$IDX/$NITEMS- Do you want to get value of field [$key] (base64=$USEBASE64) [Y/n]? " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[1-9|Y|y]$ ]]
        then
            continue;
        fi
    fi
    echo -e "---\n- name:  $key"
    if [ "$USEBASE64" = true ]; then
        echo "  value: " $( echo $ITEMS | jq -r ".[$key]" | base64 -d)
    else
        echo "  value: " $( echo $ITEMS | jq -r ".[$key]")
    fi
    # TODO check if it is a fullchain.pem, show the enddate
    CERT=$(echo $ITEMS | jq -r ".[$key]" | base64 -d)
    if [[ $CERT == "-----BEGIN CERTIFICATE-----"* ]]; then
        RC=$?; 
        if test "$RC" -eq 0; then 
            # Taken from https://www.baeldung.com/linux/openssl-extract-certificate-info
            echo -e "-  INFO of CER [$key]:"
            echo "  $(echo $CERT | openssl x509 -noout -subject 2>/dev/null)";
            echo -e "  dates:\n    $(echo $CERT | openssl x509 -noout --startdate 2>/dev/null)\n    $(echo $CERT | openssl x509 -noout --enddate 2>/dev/null)";
            echo "  $(echo $CERT | openssl x509 -noout -issuer -nameopt lname -nameopt sep_multiline  2>/dev/null)";
        fi;
    fi;
    
    # eg.  openssl x509 -enddate -noout -in   /projects/certificates/ita.es/fullchain.pem 
    echo "---"
done