#!/bin/bash
# logging the output
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/tmp/installtools.log 2>&1

MYUSER="$(whoami)"
# Install deps
apt update -y 
apt install -y ca-certificates curl gnupg software-properties-common
# functions
is_root_user() {
  if [[ $EUID != 0 ]]; then
    return 1
  fi
  return 0
}
# Banners
banner_start() {
  clear;
echo "******************"
echo "Simple script to install a suite of tools on an Ubuntu OS"
echo "This should be ran as your user - not root, don't be that guy..."
echo "If in doubt just add your user to the sudoers group."
echo "This installs: Ansible, Docker, Docker-compose, Helm, kubectl, Minikube, Terraform."
echo "Can be run on a linux host/vm or on WSL."
echo "******************"
}
# Start install
start_install() {
    banner_start
    if is_root_user; then
        echo "ERROR: You must not be the root user. Exiting..." 2>&1
        echo  2>&1
        exit 1
    fi
# Adding repo's and keys
# Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
# Minikube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
# kubectl
    curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
# helm
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
# terraform
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# actual installs
    apt update -y 
    sudo apt install -y ansible bash-completion docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    sudo install -o root -g root -m 0755 kubectl /usr/bin/kubectl
    sudo echo -e "source <(kubectl completion bash)" ~/.bashrc
    source ~/.bashrc
# finishing steps:
    sudo usermod -aG docker $MYUSER
    minikube config set driver docker
# Banner and exit
    banner_end
    exit 0
}
# banner end
banner_end() {
  clear;
echo "******************"
echo "Install done - make sure to reboot to set everything"
echo "Then test!"
echo "Here are some helpful testing commands"
echo "ansible --version (checks version)"
echo "docker run hello-world (runs a conatiner that prints hello-world to console)"
echo "minikube start (then) minikube status (should download and print out status)"
echo "kubectl get nodes (then) kubectl get pod -A (run after minikube start)"
echo "helm version (checks version)"
echo "terraform --version (checks version)"
echo "******************"
}

# Helpful Commands
# "minikube start" - Starts a Kubernetes cluster with a single node running both the control plane and the worker.
# "minikube start --nodes 3"  Starts a Kubernetes cluster with 3 nodes.
# "minikube stop" - Stops the cluster while saving its state. Running minikube start will resume it from the last state.
# "minikube delete" - Deletes the Kubernetes cluster.

# That's all folks!