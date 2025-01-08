#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

shopt -s expand_aliases
[ -f ~/.bash_aliases ] && source ~/.bash_aliases;
function createArtifact() {
    shopt -s expand_aliases
    [ -f ~/.bash_aliases ] && source ~/.bash_aliases;
    # createArtifact <NAMESPACE> <ARTIFACT> <ARTIFACTNAME> <CREATE_CMD>\
    #                   <DELETEIFEXISTS=true>
    FATAL_ERROR=false;
    [[ "$#" -gt 0 ]] && NAMESPACE=$1; shift || FATAL_ERROR=true;
    [[ "$#" -gt 0 ]] && ARTIFACT=$1; shift || FATAL_ERROR=true;
    [[ "$#" -gt 0 ]] && ARTIFACTNAME=$1; shift || FATAL_ERROR=true;
    [[ "$#" -gt 0 ]] && CREATE_CMD=$1; shift || FATAL_ERROR=true;
    [[ "$#" -gt 0 ]] && DELETEIFEXISTS=$1; shift || DELETEIFEXISTS=true;
    [ "$FATAL_ERROR" == true ] && echo "Missing mandatory param at createArtifact func">&2 exit

    if [[ "$ARTIFACT" =~ ^[ns|pv]+$ ]]; then
        NSCMD=""
        NSMSG=""
    else
        NSCMD="-n $NAMESPACE"
        NSMSG="in NS $NAMESPACE"
    fi
    
    INFO=$(kGet $ARTIFACT $ARTIFACTNAME $NSCMD -v)
    if [[ "${#INFO}" -eq 0 ]]; then
        echo "# Creating $ARTIFACT $ARTIFACTNAME $NSMSG">&2;
        eval "$CREATE_CMD"; 
    elif [[ "$DELETEIFEXISTS" == true ]]; then
        echo "# Deleting $ARTIFACT $ARTIFACTNAME $NSMSG">&2;
        CMD="kubectl delete $NSCMD $ARTIFACT $ARTIFACTNAME"
        echo "Running CMD=$CMD"
        $CMD>&2;
        echo "# Creating $ARTIFACT $ARTIFACTNAME $NSMSG">&2;
        echo "Running CMD=$CREATE_CMD"
        eval "$CREATE_CMD"; 
    else
        echo "$ARTIFACT $ARTIFACTNAME already exists $NSMSG--> Nothing is done">&2; 
    fi       
}

function readAnswer() {
    # RESPONSE=$(readAnswer <QUESTION> <DEFANSWER="">  <TIMEOUT=100> <ISQUESTION=true> <LOWERANSWER=true>)
    FATAL_ERROR=false;
    [[ "$#" -gt 0 ]] && QUESTION=$1; shift || FATAL_ERROR=true;
    [[ "$#" -gt 0 ]] && DEFANSWER=$1; shift || DEFANSWER='';
    [[ "$#" -gt 0 ]] && TIMEOUT=$(($1 + 0)); shift || TIMEOUT=15;
    [[ "$#" -gt 0 ]] && ISQUESTION=$1; shift || ISQUESTION=true;
    [[ "$#" -gt 0 ]] && LOWERANSWER=$1; shift || LOWERANSWER=true;
    [ "$FATAL_ERROR" == true ] && echo "Missing mandatory param at readAnswer function" exit;
    [ "$ISQUESTION" == true ] && HEADER="QUESTION: (timeout=${TIMEOUT}s. def=$DEFANSWER)-->" || HEADER="(timeout=${TIMEOUT}s)";
    echo -e "${HEADER}$QUESTION" >/dev/tty;
    read -t $TIMEOUT -n 1 REPLY || REPLY=$DEFANSWER;
    [ "$LOWERANSWER" == true ] && echo "${REPLY,,}" || echo $REPLY;
}

function wait4PodsDeploymentCompleted() {
    # wait4PodsDeploymentCompleted <NAMESPACE> [<TIMEOUT=20>] [<CUSTOMMSG>]
    FATAL_ERROR=false;
    [[ "$#" -gt 0 ]] && NAMESPACE=$1; shift || FATAL_ERROR=true;
    [[ "$#" -gt 0 ]] && TIMEOUT=$1; shift || TIMEOUT=20;
    [[ "$#" -gt 0 ]] && CUSTOMMSG_END=$1; shift || CUSTOMMSG_END="Please, be patient";
    [ "$FATAL_ERROR" == true ] && echo "Missing mandatory param at wait4PodsDeploymentCompleted func">&2 exit
    CUSTOMMSG="On the next screen wait until all the artifacts are properly deployed, then press Ctrl+C and the process will continue. $CUSTOMMSG_END"

    readAnswer "$CUSTOMMSG" "" $TIMEOUT false
    kGet -w -v -n $NAMESPACE
}