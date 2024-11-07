# DevopsTools
This project contains a set of tools based on clues to ease the life of people working with these devops tools: git, docker, k8s or helm.
- [DevopsTools](#devopstools)
  - [Deployment as a git project](#deployment-as-a-git-project)
  - [Deployment as a submodule](#deployment-as-a-submodule)
  - [Creating a git keypair certificate](#creating-a-git-keypair-certificate)
  - [Enabling access to the tools from CLI](#enabling-access-to-the-tools-from-cli)
    - [DevopsTools cloned as project](#devopstools-cloned-as-project)
    - [DevopsTools cloned as a submodule](#devopstools-cloned-as-a-submodule)
    - [Enabling access once git is up to date](#enabling-access-once-git-is-up-to-date)
  - [Third party tools](#third-party-tools)
    - [Install yq](#install-yq)
    - [Install jq](#install-jq)
  - [Install yamllint (optional)](#install-yamllint-optional)
  - [Copyright](#copyright)
  - [License](#license)

## Deployment as a git project
This project can be deployed as an issolated git project:  
```
$ git clone [-b <branchName>] --recurse-submodules git@github.com:cgonzalezITA/devopsTools.git  [<destinationFolder>]
```

## Deployment as a submodule
It can also be deployed as a submodule of a master git. [See this link for more info about git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)  
To deploy this GIT project as a submodule of a parent git, run the following command:
```
$ git submodule add [-b <MODULEBRANCH. eg:dev>] <MODULEGIT. eg: git@github.com:cgonzalezITA/devopsTools.git>  [<HOSTDESTINATIONFOLDER>]  
```
NOTE: If the main git has been just cloned, the submodule code may not available, hence, the following command has to be run (remember to jump to the proper branch running the _git checkout <DESIREDBRANCH. eg:dev>_ command):
```
$ git submodule update --init --recursive
``` 
## Creating a git keypair certificate
If opting for the **git@** ref. you will be required to have a git keypair certificate setup (the symptom is that you will be asked for the git password that does not match the user password). You will have to add hence a keypair certificate to your machine to connect to the git.  
Execute the following steps at an Ubuntu machine in which the git has to be cloned (For windows environments see the [presentation de metología del dpto ITA BDSC -git sin passwords-](https://feditmpsa.sharepoint.com/:p:/s/TD_BD_Sistemas_Cognitivos2/EUsBoj-0XsBFjQ5AVnV5UJABpygh1x9vMnwkAfGIddkt_Q?e=55cl18)):
1. (Linux & Windows) Generate the certificate
```
$ ssh-keygen -t ed25519 -C "your_email@example.com" [-f ~/.ssh/<customKeyPairName. eg: ed25519-ita>]
```

2. Copy the public certificate to the SSH Keys page of your git server (here you have the links to some of the ssh management pages):  
- [github](https://github.com/settings/keys)
- ...
```
# (Linux) To extract the public key run -replacing the key file <id_ed25519.pub> by the generated one at step 1):      
$ cat ~/.ssh/id_ed25519.pub
# Output must be something similar to:
ssh-ed25519 AAAAC3...olVN your_email@example.com
```

3. (Linux & Windows) Add the private key to the authorizes_keys in your working machine (the key file <id_ed25519.pub> should be replaced by the just generated one):
```
# Activate the ssh-agent service:
$ eval $(ssh-agent -s)
Agent pid 1093987

# Add the certificate
$ ssh-add ~/.ssh/id_ed25519  
Identity added: <path to your certificate file> (“your_email@example.com”)
```

4. Automatize the registration of the private keys  
Presious steps need to be added to the user **~/.bashrc** file to register the keys on each new terminal session (CLI session)
```
$ vi ~/.bashrc
# At the end of the file add the lines to start the agent and to register the keys:
  ...
  # Custom initialization
  eval `ssh-agent -s` > /dev/null
  echo Adding certificates to the ssh-agent...
  ssh-add ~/.ssh/id_ed25519-key1
  ...
  ssh-add ~/.ssh/id_ed25519-keyN
```

## Enabling access to the tools from CLI
### DevopsTools cloned as project
If the project has been just cloned, double check that you are on the desired branch
```
$ git checkout <desiredBranch>
```

### DevopsTools cloned as a submodule
Once the submodule has been cloned, checkout the proper working branch (the default one is main):
```
$ cd tools  
$ git checkout <desiredBranch>
$ git submodule update --init --recursive
```
### Enabling access once git is up to date
Most of the content of this project are scripts, so execution permission must be granted to them:
```
$ find tools -name "*.sh" -type f -exec chmod +x {} +
```

To ease the access to the scripts, several approaches can be taken. The best one is to give access to scripts via the alias ubuntu feature. This aproach speeds up the writting of the commands.  
_For example, to refer to the tool designed to deploy helm charts, only the 'h' and the 'F' chars have to be typed (plus the tab key). 
```
$ hF+<tab> --> hFileCommand._
```
- 'g' commands refer to GIT commands.
- 'd' commands refer to DOCKER commands.
- 'k' commands refer to KUBERNETES commands.
- 'h' commands refer to Helm commands.
- 'f' commands refer to file commands.
  

1. Option 1- To enable the use of alias feature, add alias to the used scripts:
```
$vi ~/.bash_aliases  
# Remember to customize the _TOOLSFOLDER env var.
export _TOOLSFOLDER="<fullPathToYourDevopsTools_folder>" 
alias _fGetFile='$_TOOLSFOLDER/fTools/_fGetFile.sh'
alias gPushAll='$_TOOLSFOLDER/gTools/gPushAll.sh'
alias gFreeze='$_TOOLSFOLDER/gTools/gFreeze.sh'
alias gCommit='$_TOOLSFOLDER/gTools/gCommit.sh'
alias gInfo='$_TOOLSFOLDER/gTools/gInfo.sh'
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
```
$ . ~/.bash_aliases
```

2. Option 2- Add the path to the different folders to the $PATH env var:
```
$ $vi ~/.bashrc  
```
Search for the section in which the PATH ENV var is defined. Something like export PATH... and  
Add the tool folders:
```
export _TOOLSFOLDER="/project/tools"
export PATH="$__TOOLSFOLDER/fTools:$_TOOLSFOLDER/dTools:$_TOOLSFOLDER/gTools:$_TOOLSFOLDER/dTools:$_TOOLSFOLDER/kTools:$_TOOLSFOLDER/hTools:$PATH"
```
Do not forget to restart the terminal to apply the changes.  
```
$ . ~/.bashrc
```

## Third party tools
These scripts rely some of its features on some tools that must be installed in the machine to benefit from them:

### Install yq
The yq is a tool to analyze yaml files.
```
        wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ./yq && chmod +x ./yq && sudo mv ./yq /usr/bin"
```
### Install jq
jq is a tool to analyze json files
```
  sudo apt-get install jq
```
## Install yamllint (optional)
```
# yamllint used to debug yaml files (used by kFileCommand)
npm install -g yaml-lint
```

## Copyright
See the [Copyright section of the LICENSE file](LICENSE.md#copyright)

## License
See the [License section of the LICENSE file](LICENSE.md#license)
