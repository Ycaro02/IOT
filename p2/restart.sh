#!/bin/bash

vagrant destroy -f
vagrant up

# export SERVER_IP=192.168.56.110

# rm -rf ~/.kube
# mkdir -p ~/.kube

# until vagrant ssh nfourS -c "bash -c '[ -f /etc/rancher/k3s/k3s.yaml ]'"; do
#     echo "Waiting for k3s server to be ready..."
#     sleep 5
# done

# vagrant scp nfourS:/etc/rancher/k3s/k3s.yaml ~/.kube/config
# sed -i "s/127.0.0.1/$SERVER_IP/g" ~/.kube/config

# export KUBECONFIG=~/.kube/config

# Create ConfigMap for app1 index.html
# app1-index is referenced in hello-world.yaml deployment
# kubectl create configmap app1-index --from-file ./index.html

# kubectl apply -f ./test.sh