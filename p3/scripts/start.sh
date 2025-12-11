#!/bin/bash

source ../sh-utils/utils.sh ../sh-utils/bash_log.sh

# Install dependencies and add user to docker group
loop_install_deps
add_docker_groups

# Delete existing k3d cluster and create a new one
k3d cluster delete mycluster 
k3d cluster create mycluster --port "80:80@loadbalancer" --port "443:443@loadbalancer"

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd patch configmap argocd-cm --type merge  -p '{"data":{"repository.refresh": "60s"}}' 2>&1

# Wait for ArgoCD to be ready
wait_for_argo

# Create development namespace, and ArgoCD applications
kubectl create namespace dev
kubectl apply -n argocd -f ./confs/argo-app.yaml

# Add /etc/hosts entry
add_etc_hosts_entry "127.0.0.1" "will-app.com"

# Start watch command to monitor ArgoCD application status
watch "echo Waiting for argo app to be deployed, press Ctrl+C to stop this watch command; kubectl describe app -n argocd | tail"


