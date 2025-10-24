#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE

function deployDevopTools() {
    [[ "$#" -gt 0 ]] && DEVTOOLS_FOLDER=$1; shift || DEVTOOLS_FOLDER=$1="$(pwd)";
    # deployDevopTools <DDEVTOOLS_FOLDER=$(pwd)>
    DEVTOOLS_GH_HTTPS="https://github.com/cgonzalezITA/devopsTools.git"
    # if [[ "$#" -gt 0 ]]; then DEVTOOLS_FOLDERNAME=$1 shift; else DEVTOOLS_FOLDERNAME="devopTools"; fi
    # if [[ "$#" -gt 0 ]]; then DEVTOOLS_FOLDERBASE=$1 shift; else DEVTOOLS_FOLDERBASE="$(pwd)"; fi
    # DEVTOOLS_FOLDER=$DEVTOOLS_FOLDERBASE/$DEVTOOLS_FOLDERNAME;
    echo "DEVTOOLS_FOLDER=[$DEVTOOLS_FOLDER]"
    # REPLY='y'
    # if [[ ! -d $DEVTOOLS_FOLDERBASE ]]; then
    #     echo "ERROR: Folder '$DEVTOOLS_FOLDERBASE' must exist";
    #     [ "$CALLMODE" == "executed" ] && exit -1 || return -1;
    # fi
    # echo "# git clone devopTools into $DEVTOOLS_FOLDERNAME folder"
    # if [[ -d $DEVTOOLS_FOLDER ]]; then
    #     REPLY=$(readAnswer "Folder $DEVTOOLS_FOLDER already exists. Do you want to delete it to reinstall the devopTools? (Y|n*)" \
    #             'n')
    #     if [ $REPLY == 'y' ]; then
    #         sudo rm $DEVTOOLS_FOLDER -R
    #     else
    #         CURRENT_FOLDER=$(pwd)
    #         cd $DEVTOOLS_FOLDER
    #         git pull
    #         cd $CURRENT_FOLDER
    #     fi
    # fi
    # if [ $REPLY == 'y' ]; then
    #     CMD="git clone $DEVTOOLS_GH_HTTPS \"$DEVTOOLS_FOLDER\""
    #     bash -c "$CMD"
    echo "# add exec permissions to the devopTools"
    CMD="find \"$DEVTOOLS_FOLDER\" -name \"*.sh\" -type f -exec chmod +x {} +"
    eval "$CMD"
    
    MSG="# To use aliases, the ~/.bash_aliases file must contain a few aliases. Do you want to add them?"
    if [ $(readAnswer "$MSG (y*|n)" 'y') == 'y' ]; then
        cat <<EOF >> ~/.bash_aliases
# --- devopTools aliases (Visit $DEVTOOLS_GH_HTTPS)
export _TOOLSFOLDER="$DEVTOOLS_FOLDER"
alias _fGetFile='\$_TOOLSFOLDER/fTools/_fGetFile.sh'
alias gPushAll='\$_TOOLSFOLDER/gTools/gPushAll.sh'
alias gFreeze='\$_TOOLSFOLDER/gTools/gFreeze.sh'
alias gCommit='\$_TOOLSFOLDER/gTools/gCommit.sh'
alias gInfo='\$_TOOLSFOLDER/gTools/gInfo.sh'
alias gSearchTextInRepos='\$_TOOLSFOLDER/gTools/gSearchTextInRepos.sh'
alias _dGetContainers='\$_TOOLSFOLDER/dTools/_dGetContainers.sh'
alias dLogs='\$_TOOLSFOLDER/dTools/dLogs.sh'
alias dCompose='\$_TOOLSFOLDER/dTools/dCompose.sh'
alias dExec='\$_TOOLSFOLDER/dTools/dExec.sh'
alias dGet='\$_TOOLSFOLDER/dTools/dGet.sh'
alias dInspect='\$_TOOLSFOLDER/dTools/dInspect.sh'
alias dRemove='\$_TOOLSFOLDER/dTools/dRemove.sh'
alias kSecret-show='\$_TOOLSFOLDER/kTools/kSecret-show.sh'
alias kExec='\$_TOOLSFOLDER/kTools/kExec.sh'
alias kGet='\$_TOOLSFOLDER/kTools/kGet.sh'
alias kFileCommand='\$_TOOLSFOLDER/kTools/kFileCommand.sh'
alias _kGetNamespace='\$_TOOLSFOLDER/kTools/_kGetNamespace.sh'
alias kSecret-create4Domain='\$_TOOLSFOLDER/kTools/kSecret-create4Domain.sh'
alias kDescribe='\$_TOOLSFOLDER/kTools/kDescribe.sh'
alias kLogs='\$_TOOLSFOLDER/kTools/kLogs.sh'
alias _kGetArtifact='\$_TOOLSFOLDER/kTools/_kGetArtifact.sh'
alias kSecret-createGeneric='\$_TOOLSFOLDER/kTools/kSecret-createGeneric.sh'
alias kRemoveRestart='\$_TOOLSFOLDER/kTools/kRemoveRestart.sh'
alias hFileCommand='\$_TOOLSFOLDER/hTools/hFileCommand.sh'
pEnvironment() {
  # Defined as function to keep the actions run on the shell
    . "\$_TOOLSFOLDER/pTools/pEnvironment.sh"  "\$@"
}
EOF
        $(readAnswer "Review the ~/.bash_aliases file to check the content is not duplicated nor contains errors.\n\
        Press a key to continue" '' 15 false false);        
    fi
    # fi
    echo "# Activating the aliases..."
    shopt -s expand_aliases
    . ~/.bash_aliases

    if [ $(readAnswer "Install yq if not installed (y*|n)" 'y') == 'y' ]; then
        echo "Check yq is installed"
        VERSION=$(yq --version 2>/dev/null)
        if [[ "$?" -ne 0 ]]; then
            echo -e "❌\ninstall yq"
            wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ./yq && chmod +x ./yq && sudo mv ./yq /usr/bin
        else
            echo ✅ jq is installed $(yq --version)
        fi
    fi

    if [ $(readAnswer "Install jq if not installed (y*|n)" 'y') == 'y' ]; then
        echo "Checking jq is installed"
        VERSION=$(jq --version 2>/dev/null)
        if [[ "$?" -ne 0 ]]; then
            echo -e "❌\ninstall yq"
            sudo apt-get install jq
        else
            echo ✅ jq is installed $(jq --version)
        fi
    fi

    if [ $(readAnswer "Install kubectl if not installed (y*|n)" 'n') == 'y' ]; then
        if ! command -v kubectl &> /dev/null; then
            echo "❌ kubectl not found. Installing latest version..."
           
            # Exit immediately if a command exits with a non-zero status.
            set -e

            echo "--- Step 1: Installing dependencies and ensuring system is up-to-date ---"
            sudo apt update
            sudo apt install -y apt-transport-https ca-certificates curl gpg

            echo ""
            echo "--- Step 2: Downloading and adding the Kubernetes GPG key ---"
            # Download and detach the GPG key
            curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
            sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

            echo ""
            echo "--- Step 3: Adding the Kubernetes APT repository (v1.30 stream) ---"
            # Add the repository definition
            echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

            echo ""
            echo "--- Step 4: Updating package index and installing kubectl ---"
            sudo apt update
            sudo apt install -y kubectl

            echo ""
            echo "--- Installation complete! Verifying version ---"
            # kubectl version --client

            echo "Script finished successfully. kubectl is now installed."
            # sudo mv kubectl /usr/local/bin/
        fi
        if command -v kubectl version --client&> /dev/null; then
            echo "✅🆗 kubectl is already installed: $(kubectl version --client)"
        fi
    fi

    if [ $(readAnswer "Install microk8s if not installed (Select n*, or phase 1 of installation). Choose n|1" 'n') == '1' ]; then
        echo "Checking microk8s (phase 1) is installed"
        VERSION=$(microk8s kubectl get pods 2>/dev/null)
        if [[ "$?" -ne 0 ]]; then
            echo -e "❌\ninstall microk8s (phase 1)"
            echo -e "After this phase finished, rerun the script '$SCRIPTNAME'"
            $BASEDIR/installMicrok8s.sh 1
            # sudo apt-get install jq
        else
            echo "✅ microk8s (phase 1) seems to be installed"
        fi
    fi
    if [ $(readAnswer "Install microk8s if not installed (Select n*, phase 2 of installation). Choose n|2" 'n') == '2' ]; then
        echo "Checking microk8s (phase 2) is installed"
        VERSION=$(kubectl get pods 2>/dev/null)
        if [[ "$?" -ne 0 ]]; then
            echo -e "❌\ninstall microk8s (phase 2)"
            $BASEDIR/installMicrok8s.sh 2
        else
            echo "✅ microk8s (phase 2) seems to be installed"
        fi
    fi

    # Installs helm
    if [ $(readAnswer "Install helm if not installed (y*|n)" 'n') == 'y' ]; then
        if ! command -v helm &> /dev/null; then
            echo "❌ Helm not found. Installing..."
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        fi
        if command -v helm &> /dev/null; then
            echo "✅🆗 Helm is already installed: $(helm version --short)"
        else
            echo "❌ Helm could not be installed"
        fi
    fi

}

#---------------------------------------------- main program ------------------------
DEVTOOLS_FOLDERBASE="$(pwd)";
deployDevopTools "$DEVTOOLS_FOLDERBASE"