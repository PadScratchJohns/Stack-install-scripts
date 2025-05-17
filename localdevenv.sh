#!/bin/bash
# Intro - simple script to install a suite of tools on an Ubuntu OS
# This should be ran as your user - not root, don't be that guy... If in doubt just add your user to the sudoers group. 
# This installs: Ansible, Docker, Docker-compose, Helm, kubectl, Minikube, Terraform.
# Can be run on a linux host/vm or on WSL.
# vars
MYUSER="$(whoami)"
# Install deps
apt update -y 
apt install -y ca-certificates curl gnupg software-properties-common

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

# installs
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

# make sure to reboot, then test!
# tests: just run below without quotes
# ansible "ansible --version"
# docker "docker run hello-world" it should print hello world container. 
# minikube "minikube start" then "minikube status" 
# kubectl "kubectl get nodes" then "kubectl get pod -A" - run this after minikube
# helm "helm version"
# terraform "terraform --version"

# Helpful Commands
# "minikube start" - Starts a Kubernetes cluster with a single node running both the control plane and the worker.
# "minikube start --nodes 3" ; Starts a Kubernetes cluster with 3 nodes.
# "minikube stop" - Stops the cluster while saving its state. Running minikube start will resume it from the last state.
# "minikube delete" - Deletes the Kubernetes cluster.

# That's all folks!