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
HEADERS_FOLDER=./tools/fTools
HEADERFILE_PATH=$HEADERS_FOLDER/resources/pythonHeader.txt

SRC_FOLDER=./tools/dTools
python3 $HEADERS_FOLDER/python_add-file-headers.py sh $HEADERFILE_PATH $SRC_FOLDER

SRC_FOLDER=./tools/fTools
python3 $HEADERS_FOLDER/python_add-file-headers.py sh $HEADERFILE_PATH $SRC_FOLDER

SRC_FOLDER=./tools/gTools
python3 $HEADERS_FOLDER/python_add-file-headers.py sh $HEADERFILE_PATH $SRC_FOLDER

SRC_FOLDER=./tools/hTools
python3 $HEADERS_FOLDER/python_add-file-headers.py sh $HEADERFILE_PATH $SRC_FOLDER

SRC_FOLDER=./tools/kTools
python3 $HEADERS_FOLDER/python_add-file-headers.py sh $HEADERFILE_PATH $SRC_FOLDER

SRC_FOLDER=./tools/pTools
python3 $HEADERS_FOLDER/python_add-file-headers.py sh $HEADERFILE_PATH $SRC_FOLDER
