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
#  "USAGE namespace.sh <namespace clue> [<callMode:asScript*|asFunction>]"
# Returns the namespace from the clue or generates an error
# if test "$#" -gt 2; then CALLMODE=$2; else CALLMODE="asScript"; fi
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi

if test "$#" -lt 1; then
    echo "ERROR: <namespace clue> is mandatory"
    [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
fi
NAMESPACECLUE=$1

NAMESPACE=$(kubectl get namespace -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -i "$NAMESPACECLUE")
if test "${#NAMESPACE}" -eq 0; then
    echo ERROR: No NAMESPACE has been found for namespace clue [$NAMESPACECLUE]
    if [ "$CALLMODE" == "executed" ]; then exit -2; else return -2; fi
fi

NLINES=$(echo "$NAMESPACE" | wc -l)
if test "$NLINES" -ne 1; then
    echo ERROR: NAMESPACE clue [$NAMESPACECLUE] is too generic. [$NLINES] matches have been found: [$NAMESPACE]
    if [ "$CALLMODE" == "executed" ]; then exit -3; else return -3; fi
fi
echo $NAMESPACE