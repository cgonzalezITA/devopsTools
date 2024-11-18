# Python tools
This folder contains infos to help working with python projects.
## Index:
- [Python tools](#python-tools)
  - [Index:](#index)
  - [Install python](#install-python)
  - [Create a python environment](#create-a-python-environment)
    - [Launch de environment in the host](#launch-de-environment-in-the-host)
    - [Install an environment file](#install-an-environment-file)
    - [Debugging a python project](#debugging-a-python-project)
    - [To restart a flask app whenever a change happens](#to-restart-a-flask-app-whenever-a-change-happens)
  - [Retrieval of the minimum set of required requirements](#retrieval-of-the-minimum-set-of-required-requirements)
    - [How does pipereqs work?](#how-does-pipereqs-work)
    - [Basic commands](#basic-commands)
  - [Install and setup an environment using Conda](#install-and-setup-an-environment-using-conda)

## Install python
https://deepnote.com/app/mauriciojacobo/Instalando-Python-310-en-Ubuntu-63add209-89c0-4cee-b6c1-0db890b6dfbf

## Create a python environment
To install on the host the required python libraries it is strongly recommended to create a custom env  
```shell
# Creates the env for the project
ENVROOTFOLDER=/python/.envs # This is just a proposal, feel free to change it
sudo mkdir -p  $ENVROOTFOLDER
ENVNAME=TOBECUSTOMIZED # Use a project descriptive name
# Maybe you have to install the venv tools
PYTHONCMD=$(which python) # This command may change depending on the python version installed on the host.
# venv is required. Its installation depends on the python version used: eg. sudo apt install $PYTHONCMD -venv; sudo apt install python3-venv, sudo apt install python3.12-venv ...
# python-distutils is required. Its installation depends on the python version used: eg. sudo apt install python3.12-distutils
$PYTHONCMD -m venv --copies $ENVROOTFOLDER/$ENVNAME 
```

### Launch de environment in the host  
```shell
# Activate the env
export PYTHONENV=$ENVROOTFOLDER/$ENVNAME/bin  
source $PYTHONENV/activate  

# Deactivate a python env 
deactivate
```

### Install an environment file
```shell
# pip command has to be installed. eg: sudo apt install python3-pip
pip install --no-cache-dir -r src/main/python/requirements.txt
```

### Debugging a python project
To debug in VSCode, install plugin "Python extension for Visual Studio Code"  
Add a configuration similar to this one to the _.vscode/launch.json_
```json
{
    "name": "P:RL4WH-API",
    "type": "debugpy",
    "python": "/python/.envs/reinforcement4learning/bin/python",
    "request": "launch",
    "program": "/projects/Reinforcement_learning_4_ware_houses/api/src/main/python/OPPy/main.py",
    "console": "integratedTerminal",
    "env": {
        "PYTHONPATHS": "/projects/Reinforcement_learning_4_ware_houses/api/src/main/python",
        "PROJECTNAME": "Reinforcement Learning 4 WareHouses API",
        "LOGSPATH": "./logs",
        "LOGLEVEL": "INFO",
        "PATH_2ROOT"="/projects/Reinforcement_learning_4_ware_houses/api/src/main/python"
        "PATH_2MODELS"="/projects/Reinforcement_learning_4_ware_houses/api/src/main/models"
    }
}
```

### To restart a flask app whenever a change happens
At the docker compose file, use the _watchmedo_ command:
```shell
    # command: 
      # This command restart the server whenever a change (in a file matching the patterms) happens is any of the folders. \
      # This command has a meaning if both /models and /app are mounted as volumes:
      sh -c "watchmedo auto-restart --directory=/app --directory=/models --patterns='*.py;*.csv;*.pth' --recursive -- python ./OPPy/main.py 5000"
```
At the dockerFile, the _watchmedo_ tool has to be installed:
```docker
FROM python:3.12.4-slim
...
RUN apt-get update && \
    apt-get clean && \
    pip install --upgrade pip
RUN pip install watchdog
...
```

## Retrieval of the minimum set of required requirements
pipreqs is a command-line tool in Python used to automatically generate a requirements.txt file based on a project's imports. This file is essential in many Python projects as it lists all the dependencies needed to run the code.

### How does pipereqs work?
Directory Scanning: pipreqs scans files in a specific directory (usually the root directory of the project) for Python package imports.
Generation of requirements.txt: From the detected imports, pipreqs creates a requirements.txt file that lists the necessary packages and their versions. This is useful for sharing or deploying projects, as it allows others to quickly install the necessary dependencies with `pip install -r requirements.txt`.

### Basic commands
```shell
pip install pipreqs
pipreqs /ruta/a/tu/proyecto
pipreqs .
```

## Install and setup an environment using Conda
```shell
# Taken from https://docs.anaconda.com/miniconda/
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh

# Once installed, it has to be activated via the command
source ~/miniconda3/bin/activate

# Create an environment
ENVFOLDER=xxx # Customize. eg. /python/.envs/conda-fiwaredsc
conda create  python=3.11.5 -p $ENVFOLDER

# Activate the environment
conda activate $ENVFOLDER

# Install a requirements file
pip install -r src/main/python/requirements.txt

# ipykernel library is required to run jupyter notebooks
pip install ipykernel
```
