#!/bin/bash

echo ARGS: $@

if [ "$1" == "server" ]; then
   curl -sfL https://get.k3s.io | K3S_TOKEN=my-cluster-token sh -s - server --write-kubeconfig-mode 644 --node-ip 192.168.56.110 --flannel-iface eth1
elif [ "$1" == "agent" ]; then
    curl -sfL https://get.k3s.io | K3S_TOKEN=my-cluster-token K3S_URL=https://192.168.56.110:6443 sh -s - agent --node-ip 192.168.56.111 --flannel-iface eth1
else
    echo "Unknown argument: $1"
    exit 1
fi

echo "alias k='kubectl'" >> /home/vagrant/.bashrc


