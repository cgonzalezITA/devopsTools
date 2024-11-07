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
# sudo docker rm -f pTest
PYTHONSOURCECODEPATH=/project/gastricAITool/git/main/python/WebServices/GastricAIToolModelExecutorWS/
DOCKERBUILDPATH=$PYTHONSOURCECODEPATH/docker/images/gastricaitool_diagnostic_prognostic
IMAGENAME=gastricaitool_diagnostic_prognostic
VERSION=ast.01.10.01

echo Sincying...

CLONEDCODE_PATH=$DOCKERBUILDPATH/tmp/code

PYTHONENV=/python/.envs/gaitool_modelExecutorEnv3/
CLONEDCODE_PATH_PYTHONENV=$CLONEDCODE_PATH/pythonEnv
mkdir -p $CLONEDCODE_PATH_PYTHONENV
rsync -av --exclude=docker --exclude=nginx --exclude=*.sh --exclude=__pycache__ --exclude=.vscode $PYTHONENV $CLONEDCODE_PATH_PYTHONENV

PYTHONLIBSPATH=/project/gastricAITool/git/main/python/Tools/
CLONEDCODE_PATH_PYTHON=$CLONEDCODE_PATH/python/tools
mkdir -p $CLONEDCODE_PATH_PYTHON
rsync -av --exclude=docker --exclude=nginx --exclude=*.sh --exclude=__pycache__ --exclude=.vscode $PYTHONSOURCECODEPATH $CLONEDCODE_PATH_PYTHON
rsync -av --exclude=docker --exclude=nginx --exclude=*.sh --exclude=__pycache__ --exclude=.vscode $PYTHONLIBSPATH $CLONEDCODE_PATH_PYTHON

# CLONEDCODE_PATH_MODELDATA=$CLONEDCODE_PATH/data
# DATAPATH=/project/gastricAITool/git/data/*
# mkdir -p $CLONEDCODE_PATH_DATA
# rsync -av --exclude=docker --exclude=nginx --exclude=*.sh --exclude=__pycache__ --exclude=.vscode $DATAPATH $CLONEDCODE_PATH_DATA


CLONEDCODE_PATH_DATA=$CLONEDCODE_PATH/python/model
MODELPATH=/project/gastricAITool/git/main/python/model/*
mkdir -p $CLONEDCODE_PATH_DATA
rsync -av --exclude=docker --exclude=nginx --exclude=*.sh --exclude=__pycache__ --exclude=.vscode $MODELPATH $CLONEDCODE_PATH_DATA

CLONEDCODE_PATH_DATA=$CLONEDCODE_PATH/data/model
MODELDATAPATH=/project/gastricAITool/git/main/data_gk/*
mkdir -p $CLONEDCODE_PATH_DATA
rsync -av --exclude=docker --exclude=nginx --exclude=*.sh --exclude=__pycache__ --exclude=.vscode $MODELDATAPATH $CLONEDCODE_PATH_DATA

PYTHONLIBSPATH=/project/gastricAITool/git/main/python/WebServices/GastricAIToolModelExecutorWS
CLONEDCODE_PATH_PYTHON=$CLONEDCODE_PATH/python
mkdir -p $CLONEDCODE_PATH_PYTHON
rsync -av --exclude=docker --exclude=nginx --exclude=*.sh --exclude=__pycache__ --exclude=.vscode $PYTHONSOURCECODEPATH $CLONEDCODE_PATH_PYTHON
rsync -av --exclude=docker --exclude=nginx --exclude=*.sh --exclude=__pycache__ --exclude=.vscode $PYTHONLIBSPATH $CLONEDCODE_PATH_PYTHON



IMAGENAMES="-t $IMAGENAME:latest -t $IMAGENAME:$VERSION -t registry.seclab.local/gatekeeper/gastricaitool/$IMAGENAME:latest -t registry.seclab.local/gatekeeper/gastricaitool/$IMAGENAME:$VERSION"
echo Building image $IMAGENAMES...
docker build $IMAGENAMES .