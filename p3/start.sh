#!/bin/bash



function wait_for_argo {
	# Wait first init then wait for argocd-server to be ready
	
    # sleep 5
	until kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-server -o jsonpath="{.items[0].status.containerStatuses[0].ready}" | grep -q true; do
    	echo "Waiting for argocd-server pod to be running..."
		sleep 5
	done
	echo "ArgoCD server is running, applying configuration..."
}



k3d cluster delete mycluster 
k3d cluster create mycluster --port "80:80@loadbalancer" --port "443:443@loadbalancer"

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

wait_for_argo

kubectl create namespace dev
kubectl apply -n argocd -f argo-app.yaml