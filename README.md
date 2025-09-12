# DevopsTools
This project contains a set of tools that based on clues, ease the life of people working with different devops tools: git, docker, k8s or helm.  
**NOTE**: These tools are designed to work on Ubuntu based systems.
- [DevopsTools](#devopstools)
  - [Deployment as a git project](#deployment-as-a-git-project)
  - [Enabling access to the tools from CLI](#enabling-access-to-the-tools-from-cli)
  - [Third party tools](#third-party-tools)
    - [Install yq](#install-yq)
    - [Install jq](#install-jq)
  - [Install yamllint (optional)](#install-yamllint-optional)
  - [Copyright](#copyright)
  - [License](#license)

## Deployment as a git project
This project is located at url **https://github.com/cgonzalezITA/devopsTools** can be deployed as an issolated git project:  
```shell
DEVTOOLS_GH_HTTPS="https://github.com/cgonzalezITA/devopsTools.git"
git clone [-b <branchName>] $DEVTOOLS_GH_HTTPS [<devopsToolsFolder>]
  # OR
DEVTOOLS_GH_GIT="git@github.com:cgonzalezITA/devopsTools.git"
git clone [-b <branchName>] $DEVTOOLS_GH_HTTPS [<devopsToolsFolder>]
```

## Enabling access to the tools from CLI
The script [deployDevopTools.sh](./quickDeployment/deployDevopTools.sh) automatizes the execution of the following commands.  

Most of the content of this project are scripts, so execution permission must be granted to them:
```shell
find devopsTools -name "*.sh" -type f -exec chmod +x {} +
```

To ease the access to the scripts, several approaches can be taken. The best one is to give access to scripts via the alias ubuntu feature. This aproach speeds up the writting of the commands.  
_For example_, to refer to the tool designed to deploy helm charts, only the 'h' and the 'F' chars have to be typed (plus the tab key). 

```shell
# Typing h+F+<tab> --> hFileCommand._
```

- 'g' commands refer to GIT commands.
- 'd' commands refer to DOCKER commands.
- 'k' commands refer to KUBERNETES commands.
- 'h' commands refer to Helm commands.
- 'f' commands refer to file commands.
  

1. Option 1- To enable the use of alias feature, add alias to the used scripts:
```shell
vi ~/.bash_aliases  
# Remember to customize the _TOOLSFOLDER env var.
export _TOOLSFOLDER="<fullPathToYourDevopsTools_folder>" 
alias _fGetFile='$_TOOLSFOLDER/fTools/_fGetFile.sh'
alias gPushAll='$_TOOLSFOLDER/gTools/gPushAll.sh'
alias gFreeze='$_TOOLSFOLDER/gTools/gFreeze.sh'
alias gCommit='$_TOOLSFOLDER/gTools/gCommit.sh'
alias gInfo='$_TOOLSFOLDER/gTools/gInfo.sh'
alias gSearchTextInRepos='$_TOOLSFOLDER/gTools/gSearchTextInRepos.sh'
alias _dGetContainers='$_TOOLSFOLDER/dTools/_dGetContainers.sh'
alias dLogs='$_TOOLSFOLDER/dTools/dLogs.sh'
alias dCompose='$_TOOLSFOLDER/dTools/dCompose.sh'
alias dExec='$_TOOLSFOLDER/dTools/dExec.sh'
alias dGet='$_TOOLSFOLDER/dTools/dGet.sh'
alias dInspect='$_TOOLSFOLDER/dTools/dInspect.sh'
alias dRemove='$_TOOLSFOLDER/dTools/dRemove.sh'
alias kSecret-show='$_TOOLSFOLDER/kTools/kSecret-show.sh'
alias kExec='$_TOOLSFOLDER/kTools/kExec.sh'
alias kGet='$_TOOLSFOLDER/kTools/kGet.sh'
alias kFileCommand='$_TOOLSFOLDER/kTools/kFileCommand.sh'
alias _kGetNamespace='$_TOOLSFOLDER/kTools/_kGetNamespace.sh'
alias kSecret-create4Domain='$_TOOLSFOLDER/kTools/kSecret-create4Domain.sh'
alias kDescribe='$_TOOLSFOLDER/kTools/kDescribe.sh'
alias kLogs='$_TOOLSFOLDER/kTools/kLogs.sh'
alias _kGetArtifact='$_TOOLSFOLDER/kTools/_kGetArtifact.sh'
alias kSecret-createGeneric='$_TOOLSFOLDER/kTools/kSecret-createGeneric.sh'
alias kRemoveRestart='$_TOOLSFOLDER/kTools/kRemoveRestart.sh'
alias hFileCommand='$_TOOLSFOLDER/hTools/hFileCommand.sh'
```

Do not forget to restart the terminal to apply the changes.  
```shell
. ~/.bash_aliases
```

2. Option 2- Add the path to the different folders to the $PATH env var:
```shell
vi ~/.bashrc  
```
Search for the section in which the PATH ENV var is defined. Something like export PATH... and  
Add the tool folders:
```shell
export _TOOLSFOLDER="/project/devopTools"
export PATH="$__TOOLSFOLDER/fTools:$_TOOLSFOLDER/dTools:$_TOOLSFOLDER/gTools:$_TOOLSFOLDER/dTools:$_TOOLSFOLDER/kTools:$_TOOLSFOLDER/hTools:$PATH"
```

Do not forget to restart the terminal to apply the changes.  
```shell
. ~/.bashrc
```

## Third party tools
These scripts rely some of its features on some tools that must be installed in the machine to benefit from them:

### Install yq
The yq is a tool to analyze yaml files.
```shell
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ./yq && chmod +x ./yq && sudo mv ./yq /usr/bin"
```
### Install jq
jq is a tool to analyze json files
```shell
sudo apt-get install jq
```
## Install yamllint (optional)
```shell
# yamllint used to debug yaml files (used by kFileCommand)
npm install -g yaml-lint
```

## Copyright
See the [Copyright section of the LICENSE file](LICENSE.md#copyright)

## License
See the [License section of the LICENSE file](LICENSE.md#license)
