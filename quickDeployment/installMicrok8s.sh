#!/bin/bash
SCRIPTNAME=$BASH_SOURCE
if [ "$0" == "$BASH_SOURCE" ]; then CALLMODE="executed"; else CALLMODE="sourced"; fi
BASEDIR=$(dirname "$SCRIPTNAME")
VERBOSE=true
SUBMODULE=""

. $BASEDIR/_base.sh
SCRIPTNAME=$BASH_SOURCE
[[ "$#" -gt 0 ]] && PHASE=$1; shift || PHASE="";
#---------------------------------------------- main program ------------------------
if [[ "${#PHASE}" -eq 0 ]] || [ "$PHASE" == "1" ]; then
    echo "Installing snapd ..." 
    sudo apt install snapd
    echo "Installing microk8s ..." 
    sudo snap install microk8s --classic

    echo "Adding user to group microk8s"
    sudo usermod -a -G microk8s $USER
    sudo chown -f -R $USER ~/.kube
    echo "Next step will open a new shell."
    echo ">>> To continue, run script \"$SCRIPTNAME 2\""
    exec newgrp microk8s
elif [ "$PHASE" == "2" ]; then
    echo "First test ..." 
    # microk8s kubectl get all --all-namespaces
    CMD="microk8s kubectl get pods"
    echo "Running CMD=[$CMD]"
    $($CMD)
    RC=$?
    if [[ "$RC" -ne 0 ]]; then
        echo "An error $RC has happened. Please, review the logs"
        return
    else
        echo "First test successful!"
    fi

    echo -e "\n### Enable dashboard ..." 
    microk8s enable dashboard 
    echo -e "\n### Enable dns ..." 
    microk8s enable dns 
    echo -e "\n### Enable ingress ..." 
    microk8s enable ingress

    echo "If something has failed, it may be due to an already existing installation of another k8s cluster?"

    # If you previously had minikube installed
    # minikube stop && minikube delete

    echo "Sets the KUBECONFIG env var"
    # https://discuss.kubernetes.io/t/use-kubectl-with-microk8s/5313/2
    microk8s.kubectl config view --raw > $HOME/.kube/microk8s.config
    # This command is just in case you had a previous minikube installed
    [ -f $HOME/.kube/config ] && cp $HOME/.kube/config $HOME/.kube/config.backup;
    microk8s.kubectl config view --raw > $HOME/.kube/config
    # Add next two lines to your ~/.bashrc
    #  export  KUBECONFIG=$HOME/.kube/config:$HOME/.kube/microk8s.config
    export  KUBECONFIG=$HOME/.kube/microk8s.config
    
    

MSG="# Kubeconfig path has to be registered at the KUBECONFIG env var at the ~/.bashrc to automatize its initialization\n\
Do you want to insert it automatically?"
if [ $(readAnswer "$MSG (y*|n)" 'y') == 'y' ]; then
    sudo cat <<EOF >> ~/.bashrc

# KUBECONFIG definition to use the microk8s k8s installation
#  export  KUBECONFIG=$HOME/.kube/config:$HOME/.kube/microk8s.config
export  KUBECONFIG=$HOME/.kube/microk8s.config
EOF
    if [[ "$?" -ne 0 ]]; then
        readAnswer "An error has happened. This operation requires sudo permission. Do it manually on another terminal and press any key to continue" \
            "" 120 false false
    fi
fi


    echo "Adds storage classic"
    # https://stackoverflow.com/questions/74741993/0-1-nodes-are-available-1-pod-has-unbound-immediate-persistentvolumeclaims"
    microk8s kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
    microk8s kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    echo -e "\n###"
    # Next command exposes the dashboard.
    # Open a new terminal and leave the other just with the dashboard running
    # microk8s dashboard-proxy
    CMD="kubectl get pods"
    $($CMD 2>/dev/null)
    RC=$?
    if [[ "$RC" -ne 0 ]]; then
        MSG="An error $RC has happened. Could it be that kubectl was not previously installed? Do you want to install a standalone kubectl?"
        if [ $(readAnswer "$MSG (y*|n)" 'y') == 'y' ]; then
            sudo snap install kubectl --classic
        fi
    fi

    echo "Now, you new shells should have a running microk8s cluster"
    echo "Second test using syntax kubectl ..."  
    echo "Kubectl used: $(which kubectl)"
    echo "Config used: $KUBECONFIG"
    echo "Running test CMD=[$CMD]"
    $($CMD 2>/dev/null)
    RC=$?
    if [[ "$RC" -ne 0 ]]; then
        echo "Test failed. Review logs"
    else
        echo "Second test successful!"
    fi
else
    echo "Unknown phase [$PHASE] specified, use 1 or 2"
fi