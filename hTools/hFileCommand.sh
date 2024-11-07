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

# Tries to find that the files exist
getExistingFileOrDir() {
    CCHART=$1; shift;
    FCONFIGFOLDER=$1; shift;
    ISFILE=$1; shift;
    # echo "CCHART=$CCHART"               > /dev/tty;
    # echo "FCONFIGFOLDER=$FCONFIGFOLDER" > /dev/tty;
    # echo "ISFILE=$ISFILE"               > /dev/tty;
    if [[ ! "$CCHART" =~ ^\/.*  ]]; then
        # Does not start with /, so I try to add prefix FCONFIGFOLDER
        CCHARTCANDIDATE=$(eval 'echo "$FCONFIGFOLDER/$CCHART" | sed s#//*#/#g')
        # echo "CCHARTCANDIDATE=$CCHARTCANDIDATE" > /dev/tty;
        if [ "$ISFILE" = true ]; then
            if test -f "$CCHARTCANDIDATE"; then
                CCHART=$CCHARTCANDIDATE
            fi
        else
            if test -d "$CCHARTCANDIDATE"; then
                CCHART=$CCHARTCANDIDATE
            fi
        fi
    fi
    echo $CCHART
    return 0
}


# \t-n <NamespaceClue>: Specifies a clue of the namespace to be used                                    \n
NSCLUE=""
NAMESPACE="default"
NAMESPACESET=false
NAMESPACEDESC="in default namespace."
NAMESPACEARG=""
# \t-cf: Config name pattern (def.config.*) This file contains details of the helm chart: name, ns, chart\n
CONFIGNAME_PATTERN=config.*
# \t-v: Do not show verbose info                                                                        \n
VERBOSE=true
# \t[<command>] Command to be executed against the artifact file: apply*|delete|restart"
COMMAND=""
# \t-f <folder with helm config>: Folder where the config file must be located (def value: ./HValues    \n
FOLDER_HELMBASE=./Helms
# \t-fv: Force secretname match the given clue (using this, the clue is not a clue, but the name)       \n
USECCLUE=true
CCLUE=""
CCLUEORIG=""
# EXTRACOMPONENTS=""
# \t-fvn: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
USENSCCLUE=true
# \t-b: Runs a dependency build command that is required for umbrella charts for being updated          \n
BUILDCMD=""
# \t-y: No confirmation questions are asked                                                             \n
ASK=true
# \t-vf: Value file name clue. By default the value file name is the one found at the config file, but it is overridden by this value \n
FVALUESCLUE=""
FVALUES=""
USEFVALUESCLUE=true
#############################
## Functions               ##
#############################
function help() {
    HELP=""
    if test "$#" -ge 1; then
        HELP="${1}\n"     
    fi
    # \t-f <folder with artifacts>: Folder where the artifact file must be located (def value: ./KArtifacts \n
    HELP="$HELP\nHELP: USAGE: $SCRIPTNAME [optArgs] <component clue> [<command>:install*|delete|restart|debug|idebug|test]\n 
            \t-h: Show help info                                                                                  \n
            \t-n <NamespaceClue>: Specifies a clue of the namespace to be used                                    \n
            \t-fnv: Force namespace name match the given clue (using this, the clue is not a clue, but the name)  \n
            \t-f <folder base to search for helm files>: (def value: ./Helms)                                     \n
            \t-fv: Force value match the given clue (using this, the clue is not a clue, but the name)            \n
            \t-cf: Config name pattern (def.config.*) This file contains details of the helm chart: name, ns, chart\n
            \t-vf: Value file name clue. By default the value file name is the one found at the config file, but it is overridden by this value \n
            \t-fvf: Force the given value file name is the one to be used, it is not a clue \n
            \t-v: Do not show verbose info                                                                        \n
            \t-y: No confirmation questions are asked                                                             \n
            \t-b: Runs a dependency build command that is required for umbrella charts for being updated          \n
            \t<component clue>: Clue to identify the artifact file name. all to run command on all yaml files     \n
            \t[<command>] Command to be executed against the artifact file: apply*|delete|restart|debug|test"
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
        -y | --yes ) 
            ASK=false; shift ;;
        -fv | --forcevalue ) 
            USECCLUE=false; shift ;;
        -fvn | -fnv | --forceNamespaceValue ) 
            USENSCCLUE=false; 
            shift ;;
        # \t-vf: Value file name clue. By default the value file name is the one found at the config file, but it is overridden by this value \n
        -vf | --valuefile )
            FVALUESCLUE=$2;
            shift ; shift ;;
        -fvf | --forcevaluefile ) 
            USEFVALUESCLUE=false; shift ;;
        -b | --build ) 
            BUILDCMD="-b"; shift ;;
        -cf | --configFilePattern ) 
            # \t-cf: Config name pattern (def.config.*) This file contains details of the helm chart: name, ns, chart\n
            CONFIGNAME_PATTERN=$2;
            shift ; shift ;;
        -f ) 
            FOLDER_HELMBASE=$2
            shift ; shift ;;
        -n | --namespace ) 
            # echo analyzing ns=$2;
            NAMESPACESET=true
            NSCLUE=$2
            shift ; shift ;;
        * ) 
            if [[ $1 == -* ]]; then
                echo -e $(help "ERROR: Unknown parameter [$1]");
                [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
            elif test "${#CCLUE}" -eq 0; then
                CCLUE=$1
                CCLUEORIG=$1
                shift;
            elif test "${#COMMAND}" -eq 0; then
                COMMAND=$1;
                shift;
            fi ;;
    esac
done

if test "${#CCLUE}" -eq 0; then
    echo -e $(help "# ERROR: <component clue> is mandatory");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
elif test "${#COMMAND}" -eq 0; then
    COMMAND="install"
fi

if ! test -d $FOLDER_HELMBASE;then 
    echo -e $(help "ERROR: Folder [$FOLDER_HELMBASE] must exist. Use -f option to use an alternate folder");
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
fi

if test "${#NSCLUE}" -gt 0; then
    if [ "$USENSCCLUE" = true ]; then
        shopt -s expand_aliases
        . ~/.bash_aliases
        NAMESPACEORERROR=$( _kGetNamespace $NSCLUE );
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
    FCONFIG=$CCLUE
fi
if [ "$USECCLUE" = true ]; then
    shopt -s expand_aliases
    . ~/.bash_aliases
    # Search a file named config.* in a folder alike "$CCLUE"
    getFileResult=$(_fGetFile "$FOLDER_HELMBASE" "$USECCLUE" "$CCLUE" "$CCLUE" false true "$CONFIGNAME_PATTERN" "Looking for config file");
    # echo "getFileResult=$getFileResult"
    RC=$?; 
    if test "$RC" -ne 0; then 
        echo -e $(help "  ERROR: $getFileResult");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    elif test "${#getFileResult}" -eq 0; then
        # Selected not to use the artifacts
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    else           
        FCONFIG=$getFileResult;
        # echo "FCONFIG=[$FCONFIG]" > /dev/tty;
    fi
else
    FCONFIG=$CCLUE
fi
FCONFIGFOLDER="$(dirname "${FCONFIG}")"
# echo "FCONFIGFOLDER=$FCONFIGFOLDER" > /dev/tty;
# if [ "$USECCLUE" = true ]; then
#     FCONFIG=$(find $FOLDER_HELMBASE -maxdepth 1 -name "hConfig-*$CCLUE*.*")
# else
#     FCONFIG=$CCLUE
# fi

# if test "${#FCONFIG}" -eq 0; then
#     echo -e $(help "# ERROR: No hConfig file has been found for helm component clue [$CCLUE]");
#     [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
# fi
# NLINES=$(echo "$FCONFIG" | wc -l)
# if test "$NLINES" -ne 1; then
#     echo -e $(help "# ERROR: helm component clue [$CCLUE] is too generic. [$NLINES] config matches have been found: [$FCONFIG]")
#     [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
# fi

if [[ ${FCONFIG##*.} =~ json ]]; then
    JQ_YML_CMD="jq"
elif [[ ${FCONFIG##*.} =~ ya?ml ]]; then
    JQ_YML_CMD="yq eval"
else
    echo -e $(help "# ERROR: Config file [$FCONFIG] must be json (*.json) or yaml (*.yaml)")
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
fi
if [[ $(expr length "$(which $JQ_YML_CMD)") -eq 0 ]]; then
    MSG="# ERROR: Utility [$JQ_YML_CMD] used to extract [$FCONFIG] info is not available. Please install it first.\n-[$JQ_YML_CMD]:"
    if [[ ${FCONFIG##*.} =~ ya?ml ]]; then
        MSG="$MSG wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ./yq && chmod +x ./yq && sudo mv ./yq /usr/bin";
    else
        MSG="$MSG sudo apt-get install jq";
    fi
    echo -e $(help "$MSG")    
fi
# echo "JQ_YML_CMD=[$JQ_YML_CMD]" > /dev/tty;



CNAME=`$JQ_YML_CMD '.name'      "$FCONFIG"`
# echo "JQ_YML CNAME=$CNAME" > /dev/tty;
RC=$?;
if test "$RC" -ne 0; then 
    MSG="ERROR: Problems using the yq command:\n"
    if test "$JQ_YML_CMD" == "jq"; then
        MSG="$MSG \
        The jq command is required to run the command. It can be installed using command sudo apt-get install jq"
    else # yq eval
        MSG="$MSG \
        The yq command is required to run the command. It can be installed using commands: \n \
            wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ./yq && chmod +x ./yq && sudo mv ./yq /usr/bin"
    fi
    echo -e $MSG
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
fi
CNAME=`$JQ_YML_CMD '.name'        "$FCONFIG" | tr -d '"'`
CCHART=`$JQ_YML_CMD '.chart'      "$FCONFIG" | tr -d '"'`

if test "${#FVALUESCLUE}" -gt 0; then
    if [ "$USEFVALUESCLUE" = true ]; then
        shopt -s expand_aliases
        . ~/.bash_aliases
        getFileResult=$(_fGetFile "$FCONFIGFOLDER" "true" "$FVALUESCLUE" "$FVALUESCLUE" false false "" "Looking for values file");
        RC=$?; 
        if test "$RC" -ne 0; then 
            echo -e $(help "  ERROR: $getFileResult");
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
        elif test "${#getFileResult}" -eq 0; then
            # Selected not to use the artifacts
            [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
        else           
            FVALUES=$getFileResult;
        fi
    else
        FVALUES=$FVALUESCLUE
    fi
else
    FVALUES=`$JQ_YML_CMD '.valueFile' "$FCONFIG" | tr -d '"'`
fi
VERSION=`$JQ_YML_CMD '.version'   "$FCONFIG" | tr -d '"'`
# echo "JQ_YML CNAME=$CNAME" > /dev/tty;
# echo "JQ_YML CCHART=$CCHART" > /dev/tty;
# echo "JQ_YML FVALUES=$FVALUES" > /dev/tty;
# echo "JQ_YML VERSION=$VERSION" > /dev/tty;

CCHART=$(eval 'getExistingFileOrDir "$CCHART" "$FCONFIGFOLDER" false')
FVALUES=$(eval 'getExistingFileOrDir "$FVALUES" "$FCONFIGFOLDER" true')
# echo "getExistingFileOrDir CCHART=$CCHART" > /dev/tty;
# echo "getExistingFileOrDir FVALUES=$FVALUES" > /dev/tty;

# EXTRACOMPONENTS=`$JQ_YML_CMD '.extraComponents'   $FCONFIG | tr -d '"'`
# if [ "$EXTRACOMPONENTS" == null ]; then 
#     EXTRACOMPONENTS="";
# fi
if [ "$NAMESPACESET" == false ]; then
    NAMESPACECFG=`$JQ_YML_CMD '.namespace' "$FCONFIG" | tr -d '"'`
    if [ ! "$NAMESPACECFG" == null ]; then
        NAMESPACE=$NAMESPACECFG
        NAMESPACEDESC="in namespace [$NAMESPACE]"; 
        NAMESPACEARG="-n $NAMESPACE";
        USENSCCLUE=false
    fi
fi
if [ "$FVALUES" == "null" ]; then
# if test "${#FVALUES}" -eq 0; then
    echo -e $(help "# INFO: json.valueFile not found. Looking for value file in [$FOLDER_HELMBASE] folder");
    FVALUES=$(find "$FOLDER_HELMBASE" -maxdepth 1 -name "$CCLUE*-values.yml")
    if test "${#FVALUES}" -eq 0; then
        echo -e $(help "# ERROR: No yaml values file has been found for helm component clue [$CCLUE]");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    fi
    NLINES=$(echo "$FVALUES" | wc -l)
    if test "$NLINES" -ne 1; then
        echo -e $(help "# ERROR: helm component clue [$CCLUE] is too generic. [$NLINES] matches have been found: [$FVALUES]")
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    fi
fi

if test "${#CCHART}" -eq 0; then
    echo -e "# INFO: Missing json 'chart' in [$FCONFIG]. Trying to use 'path' instead";
    CPATH=`$JQ_YML_CMD '.path' $FCONFIG | tr -d '"'`
    if test "${#CPATH}" -eq 0; then
        echo -e $(help "# ERROR: Missing json 'path' in [$FCONFIG]");
        [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
    else
        CCHART=$CPATH
    fi
fi


if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
    VERSIONDESC=""
    VERSIONARG=""
else
    VERSIONDESC="using VERSION [$VERSION]"
    VERSIONARG="--version $VERSION"
fi

if [[ "$COMMAND" =~ ^(up|start|install|u)$ ]]; then
    COMMAND="install";
elif [[ "$COMMAND" =~ ^(down|stop|del|d)$ ]]; then
    COMMAND="delete";
fi

if [ "$VERBOSE" = true ]; then
    if test "${#NAMESPACE}" -gt 0; then echo -e "# -NAMESPACE=[$NSCLUE] -> [$NAMESPACE]" | egrep --color=auto  "$NSCLUE"; else echo "# -NAMESPACE=[$NSCLUE] -> [$NAMESPACE]"; fi
    echo -e "# -NAMESPACECFG=$NAMESPACECFG         "
    echo -e "# -FOLDER_HELMBASE=[$FOLDER_HELMBASE]    " 
    if [ "$USECCLUE" = true ]; then 
        echo -e "# -CONFIG_FILE=[$CCLUE] -> [$FCONFIG]" | egrep --color=auto "$CCLUEORIG"
    else 
        echo -e "# -CONFIG_FILE=[$CCLUE] -> [$FCONFIG]"
    fi
    echo -e "# -COMMAND=[$COMMAND]                 " | egrep --color=auto "$COMMAND"
    echo -e "#  >HELM_NAME=$CNAME                  " 
    echo -e "#  >CONFIGNAME_PATTERN=$CONFIGNAME_PATTERN" 
    echo -e "#  >HELM_CHART=$CCHART                " 
    echo -e "#  >VERSION=$VERSIONARG               "
    MSG="#  >VALUES_FILE=" 
    if test "${#FVALUESCLUE}" -gt 0; then
        MSG="# >USE VALUES FILE CLUE=$USEFVALUESCLUE\n$MSG";
        MSG+="[$FVALUESCLUE]->";
    fi
    MSG+="[$FVALUES]";
    echo -e "$MSG" | sed "s/\($FVALUESCLUE\)/\x1b[31m\1\x1b[0m/g"
    if test "${#BUILDCMD}" -gt 0; then echo -e "#  >BUILD=$BUILDCMD"; fi
    echo -e "#  >ASK=[$ASK]" 
fi

if [ "$FCONFIG" == "all" ]; then
    IDX=1
    CMDF="find \"$FOLDER_HELMBASE\" -maxdepth 1 -name hConfig-*.* -type f"
    NFILES=$( /bin/bash -c "$CMDF | wc -l")
    echo "NFILES=$NFILES"
    X=""
    for filename in $(/bin/bash -c "$CMDF"); do
        CMDA="$SCRIPTNAME $BUILDCMD -v -fnv $NAMESPACEARG -f \"$FOLDER_HELMBASE\" -fv \"$filename\" $COMMAND"
        # CMDA="$SCRIPTNAME $NAMESPACEARG -v -f \"\" -fv $filename $COMMAND"
        # CMDA="helm $COMMAND $NAMESPACEARG -f $filename"
        echo -e "---\nINFO ($IDX/$NFILES): Executing command [$CMDA]"
        IDX=$(($IDX+1))
        # { err=$(cmd 2>&1 >&3 3>&-); } 3>&1
        X1=$($CMDA 2>&1)
        echo "$X1"
        X="$X\n\t---From file $filename---\n$X1"
    done
    echo -e "---\nSummary:\n$X"
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
fi
# echo -e "# INFO: Executing helm command [$COMMAND] using values from file [$FVALUES] for component [$CNAME] and chart [$CCHART] $VERSIONDESC $NAMESPACEDESC"



if test "$COMMAND" == "test"; then
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1; 
elif [[ "$COMMAND" =~ ^(restart|r)$ ]]; then
    COMMAND="restart";
    if [ "$ASK" == true ]; then ASKFLAG=""; else ASKFLAG="-y"; fi
    if test "${#FVALUESCLUE}" -gt 0; then
        FVALUESCMD=" -fvf -vf \"$FVALUES\""
    else
        FVALUESCMD=""
    fi
    echo " INFO: 1. Deleting helm [$CNAME]:[$ASKFLAG]"
    CMD="$SCRIPTNAME $ASKFLAG -fnv $NAMESPACEARG --verbose -fv \"$FCONFIG\" $FVALUESCMD delete"
    echo -e "# Running command [$CMD]"
    eval "$CMD"
    echo " INFO: 2. Installing helm [$CNAME]:"
    sleep 1

    CMD="$SCRIPTNAME $ASKFLAG -fnv $NAMESPACEARG $BUILDCMD --verbose -fv '$FCONFIG' $FVALUESCMD install"
    echo -e "# Running command [$CMD]"
    bash -c "$CMD"
    if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
fi

# EXTRACOMPONENTS_FILE=/tmp/extraComponents.yaml
# if test -f $EXTRACOMPONENTS_FILE; then
#     rm $EXTRACOMPONENTS_FILE > /dev/null 2>&1
# fi
# if [ ! -z "${EXTRACOMPONENTS}" ]; then
#     echo -e "This config file has extra components:\n---\n$EXTRACOMPONENTS\n---"
#     read -ep "Do you want to you $COMMAND them ([Y/n])? (File $EXTRACOMPONENTS_FILE will be created)" -n 1 -r
#     echo    # (optional) move to a new line
#     if [[ $REPLY =~ ^[Yy]$ ]]; then 
#         # echo -e "apiVersion: v1\nkind: List\nmetadata:\nresourceVersion: ""\nitems:\n\t"
#         echo -e "$EXTRACOMPONENTS" > $EXTRACOMPONENTS_FILE
#     fi
# fi

if test -d "$CCHART" && [ "${#BUILDCMD}" -gt 0 ]; then # Only CCHART=directory apply the --build
    CMD="helm $NAMESPACEARG dependency update '$CCHART' $VERSIONARG"
    echo -e "# Running command [$CMD]"
    bash -c "$CMD"
    echo "---"
    CMD="helm $NAMESPACEARG dependency build '$CCHART' $VERSIONARG"
    echo -e "# Running command [$CMD]"
    bash -c "$CMD"
    echo "---"
fi

COMMANDS2INSTALL=" install upgrade "
COMMANDSINVOLVEDINHELPCOMMAERROR=" $COMMANDS2INSTALL idebug "
COMMANDS2ASK4CONFIRMATION=" $COMMANDS2INSTALL idebug delete debug "
if [[ ${COMMANDS2ASK4CONFIRMATION[@]} =~ " $COMMAND " ]];  then
    if [[ ${COMMANDSINVOLVEDINHELPCOMMAERROR[@]} =~ " $COMMAND " ]] && [[ "$FVALUES" == *","* ]]; then
        MSG="WARNING: commas are treated as special chars; so error arise when used on chart paths. Do you want to continue using chart path [$CCHART]"
        echo $MSG | egrep --color=auto  "," > /dev/tty
            read -p "sure [Y/n]? " -n 1 -r 
            echo  > /dev/tty  # (optional) move to a new line
        if [[ ! $REPLY =~ ^[1Yy]$ ]]; then
            echo "NOTE: Try renaming chart path to remove the commas [$CCHART]"
            if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
        fi
    fi
    echo '---'
    if [ "$COMMAND" == "idebug" ]; then
        COMMAND="install --debug"
        CMD="helm $NAMESPACEARG $COMMAND -f \"$FVALUES\" $CNAME \"$CCHART\" $VERSIONARG 2>&1"
    elif [[ ${COMMANDS2INSTALL[@]} =~ " $COMMAND " ]];  then
        CMD="helm $NAMESPACEARG $COMMAND -f \"$FVALUES\" $CNAME \"$CCHART\" $VERSIONARG --create-namespace"
    elif [ "$COMMAND" == "delete" ]; then
        # echo "# INFO: Deleting helm $CNAME..."
        CMD="helm $NAMESPACEARG $COMMAND $CNAME"
        # if test -f $EXTRACOMPONENTS_FILE; then
        #     echo "--- extra components ---"
        #     echo "NOTE: If PV are not deleted, do not worry, or check https://stackoverflow.com/questions/55672498/kubernetes-cluster-stuck-on-removing-pv-pvc"
        #     kubectl $NAMESPACEARG delete -f $EXTRACOMPONENTS_FILE
        # fi
    elif [ "$COMMAND" == "debug" ]; then
        COMMAND="template --debug"
        CMD="helm $NAMESPACEARG $COMMAND -f \"$FVALUES\" $CNAME \"$CCHART\" $VERSIONARG 2>&1"
        if [ "$VERBOSE" = true ]; then
            echo -e "# WARNING: [$COMMAND] does not connect to the k8s API, so functions like 'lookup' and others will not retrieve valid info.\n \
            # This could lead to some misleading errors such as resources not found in the running k8s cluster\n\
            # USE idebug (Install debug) to view the real k8s generated artifacts although this command will install the chart if correct\n\
            ---"
        fi
    fi
    if [ "$VERBOSE" = true ]; then
        echo "# Running CMD=[$CMD]"
    fi
    if [ "$ASK" = true ]; then
        MSG="QUESTION: Do you want to run this command on chart [$CCHART] $NAMESPACEDESC using value file [$FVALUES]?"
        if [ "$USECCLUE" = true ]; then
            echo $MSG | egrep --color=auto  "$CCLUEORIG" > /dev/tty
        else
            echo $MSG > /dev/tty
        fi
        read -p "sure [Y/n]? " -n 1 -r 
        echo  > /dev/tty  # (optional) move to a new line
    else
        REPLY="y"
    fi
    if [[ $REPLY =~ ^[1Yy]$ ]]; then
    eval $CMD
    echo "---"
    else
        if [ "$CALLMODE" == "executed" ]; then exit; else return; fi
    fi
else
    echo "# ERROR: Unknown command [$COMMAND]"
fi