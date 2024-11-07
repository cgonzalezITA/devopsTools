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


# \t\t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# \t\t-f <folderName>: Folder where the public/private keys are located                                   \n
PATH_CERTIFICATES=""
# \t\t-tmp <folderName>: Folder where the temporal folders will be stored                                 \n
TMPFOLDER="/tmp"
# \t\t-pub <fileName>: Name of the public key file (def: fullchain.pem)                                   \n
KEY_PUB=fullchain.pem
# \t\t-priv <fileName>: Name of the private key file (def: privkey.pem)                                   \n
KEY_PRIV=privkey.pem
# \t\t-n <NamespaceClue>: Specifies a clue of the namespace in which the secret will be created           \n
NSCLUE=""
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
NAMESPACE="default"
NAMESPACEDESC="in default namespace."
NAMESPACEARG=""
# \t\t-s <secret name>: Name of the secret to be generated                                                \n
SNAME=""
# \t\t<step>*: Step of the generation 1|2|3"
STEP=""

#############################
## Functions               ##
#############################
function help() {
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs]  <secretName><step>                                           \n
          \tThis is a 3 steps process as the 1st and 3th have to be executed as sudo.                             \n
          \t1º-  sudo $SCRIPTNAME [1]                                                                             \n
          \t2º-  sudo $SCRIPTNAME [2]                                                                             \n
          \t3th- sudo $SCRIPTNAME [3]                                                                             \n
          \tParams (* params are mandatory):                                                                      \n
          \t\t-h: Show help info                                                                                  \n
          \t\t-v: Do not show verbose info                                                                        \n
          \t\t-f <folderName>: Folder where the public/private keys are located                                   \n
          \t\t-tmp <folderName>: Folder where the temporal folders will be stored (def: /tmp)                     \n
          \t\t-pub <fileName>: Name of the public key file (def: fullchain.pem)                                   \n
          \t\t-priv <fileName>: Name of the private key file (def: privkey.pem)                                   \n
          \t\t-n <NamespaceClue>: Specifies a clue of the namespace to be used.                                     \n
          \t\t                    export DEF_KTOOLS_NAMESPACE=<NSCLUE> env var to avoid having to repeat it on kTools commands  \n
          \t\t-nd: Shortcut for -n default                                                                             \n
          \t\t-fnv: Force namespace name match the given clue (using this, the clue is not a clue, but the name)   \n
          \t\t<secret name>: Name of the secret to be generated                                                \n
          \t\t<step>*: Step of the generation 1|2|3 (This is required as some steps require sudo privileges)"
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
            if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
            break ;;
        -f ) 
            PATH_CERTIFICATES=$2
            if ! test -d $PATH_CERTIFICATES;then echo -e $(help "ERROR: Folder [$PATH_CERTIFICATES] must exist");return -1; fi;
            shift ; shift ;;
        -tmp ) 
            TMPFOLDER=$2
            if ! test -d $TMPFOLDER;then echo -e $(help "ERROR: Temporal folder [$PATH_CERTIFICATES] must exist");return -1; fi;
            shift ; shift ;;
        -pub ) 
            KEY_PUB=$2
            shift ; shift ;;        
        -priv ) 
            KEY_PRIV=$2
            shift ; shift ;;        
        -n | --namespace ) 
            NSCLUE=$2
            shift ; shift ;;
        -nd | --namespace-default ) 
            NAMESPACESET=true
            NSCLUE="default"
            shift ;;
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; 
            shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
            elif test "${#SNAME}" -eq 0; then
                SNAME=$1;
                shift;
            elif test "${#STEP}" -eq 0; then
                STEP=$1;
                shift;
            fi ;;
    esac
done

if test "${#SNAME}" -eq 0; then
    echo -e $(help "ERROR: <secretName> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
elif test "${#STEP}" -eq 0; then
    echo -e $(help "ERROR: <step> is mandatory")
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
    NAMESPACEDESC="in namespace [$NAMESPACE]"; 
    NAMESPACEARG="-n $NAMESPACE"; 
fi


KEY_PRIV_SRC=$PATH_CERTIFICATES/$KEY_PRIV
KEY_PUB_SRC=$PATH_CERTIFICATES/$KEY_PUB
KEY_PRIV_DST=$TMPFOLDER/$KEY_PRIV
KEY_PUB_DST=$TMPFOLDER/$KEY_PUB

if [ "$VERBOSE" = true ]; then
  MSG="[$NSCLUE] -> [$NAMESPACE]"
  if [[ "$DEF_KTOOLS_NAMESPACE_USED" ]]; then MSG="$MSG. Taken from  DEF_KTOOLS_NAMESPACE=[$DEF_KTOOLS_NAMESPACE]"; fi
  echo "            VERBOSE=$VERBOSE"
  echo "          NAMESPACE=$MSG" | egrep --color=auto  "$NSCLUE" 
  echo "  PATH_CERTIFICATES=$PATH_CERTIFICATES"
  echo "          TMPFOLDER=$TMPFOLDER"
  echo "            KEY_PUB=$KEY_PUB"
  echo "        KEY_PUB_SRC=$KEY_PUB_SRC"
  echo "        KEY_PUB_DST=$KEY_PUB_DST"
  echo "           KEY_PRIV=$KEY_PRIV"
  echo "       KEY_PRIV_SRC=$KEY_PRIV_SRC"
  echo "       KEY_PRIV_DST=$KEY_PRIV_DST"
  echo "              SNAME=$SNAME"
  echo "              STEP=$STEP"
fi

if [ "$STEP" -eq 1 ]; then
  if [ "$VERBOSE" = true ]; then
    echo " Saving cert files [$KEY_PRIV & $KEY_PUB] from folder [$PATH_CERTIFICATES] to a temp folder [$TMPFOLDER] to avoid permission problems..."
  fi
  sudo /bin/bash -c "cat $KEY_PRIV_SRC   > $KEY_PRIV_DST"
  RC=$?; 
  if test "$RC" -ne 0; then 
    echo -e $(help "ERROR copying file [$KEY_PRIV_SRC]. Does it exists? Or [$TMPFOLDER] folder can create file [$KEY_PRIV_DST]?"); 
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
  fi;
  sudo cat $KEY_PUB_SRC    > $KEY_PUB_DST
  RC=$?; 
  if test "$RC" -ne 0; then 
    echo -e $(help "ERROR copying file [$KEY_PRIV_SRC]. Does it exists? Or [$TMPFOLDER] folder can create file [$KEY_PUB_DST]?"); 
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
  fi;
  sudo chmod 666 $KEY_PRIV_DST $KEY_PUB_DST  

  if [ "$VERBOSE" = true ]; then
    echo "  Temporal secret files have been generated. Do not forget to disable them (3th command)"
  fi
elif [ $STEP == "2" ]; then
  if test "${#SNAME}" -eq 0; then
    echo -e $(help "ERROR: No secret name has been provided for this step [$STEP]");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
  fi

  CMD="kubectl create secret tls $SNAME $NAMESPACEARG --key $KEY_PRIV_DST --cert $KEY_PUB_DST"
  if [ "$VERBOSE" = true ]; then
    echo -e "  Creating secret tls [$SNAME] using the following command...:
         \t$CMD"
  fi
  $CMD
  if [ "$VERBOSE" = true ]; then
    echo "  Secret [$SNAME] should have been created $NAMESPACEDESC Here you have the matching secrets installed at K8s:"
    kubectl get secrets $NAMESPACEARG | grep $SNAME
    echo "  NOTE: DO NOT FORGET TO DISABLE THE SECRET FILES"
  fi
elif [ $STEP == "3" ]; then
  sudo rm $KEY_PRIV_DST
  sudo rm $KEY_PUB_DST
  echo "  Temporal secret files deleted. Txs"
else
    echo -e $(help "Error: Unknown command [$STEP]")
fi
