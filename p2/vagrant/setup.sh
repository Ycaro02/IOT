#!/bin/bash

echo ARGS: $@

if [ "$1" == "server" ]; then
   curl -sfL https://get.k3s.io | K3S_TOKEN=my-cluster-token sh -s - server --write-kubeconfig-mode 644 --flannel-iface eth1
#    cat /vagrant/vagrant/k3s_install.sh | K3S_TOKEN=my-cluster-token sh -s - server --write-kubeconfig-mode 644 --node-ip 192.168.56.110 --flannel-iface eth1
else
    echo "Unknown argument: $1"
    exit 1
fi

echo "alias k='kubectl'" >> /home/vagrant/.bashrc

# until curl localhost 2>/dev/null | grep -i "404 page not found"; do
# get pod -n kube-system | grep traefik | grep Running | wc -l
until false; do
    count=$(kubectl get pod -n kube-system 2>/dev/null | grep traefik | grep Running | wc -l)
    if [ "${count}" == "2" ]; then
        echo "k3s and traefik are ready."
        break
    fi
     echo "Waiting for k3s and traefik to be ready..."
     sleep 5
done

kubectl create configmap app1-index --from-file /vagrant/app1/index.html
kubectl apply -f /vagrant/app1/app1.yaml

kubectl create configmap app2-index --from-file /vagrant/app2/index.html
kubectl apply -f /vagrant/app2/app2.yaml

kubectl create configmap app3-index --from-file /vagrant/app3/index.html
kubectl apply -f /vagrant/app3/app3.yaml
