#!/bin/bash

source ../sh-utils/utils.sh ../sh-utils/bash_log.sh

# Install dependencies, docker k3d and kubectl
loop_install_deps

# Add the current user to the docker group
add_docker_groups

# Delete existing k3d cluster
k3d cluster delete mycluster

# Create k3d cluster
k3d cluster create mycluster \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer"


# Install Helm
helm_path=`whereis helm | awk -F ':' '{print $2}' | tr -d ' '`
if [ -z "${helm_path}" ]; then
    curl -s -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
    chmod 700 get_helm.sh
    ./get_helm.sh
else
    log I "Helm is already installed at ${helm_path}"
fi

# Add GitLab Helm repository
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Create GitLab namespace
kubectl create namespace gitlab

# Start GitLab installation
helm upgrade --install gitlab gitlab/gitlab \
  --set global.hosts.domain=localhost \
  --set global.hosts.externalIP=127.0.0.1 \
  --set global.ingress.configureCertmanager=false \
  --set global.hosts.https=false \
  --set global.ingress.tls.enabled=false \
  --set global.ingress.annotations."nginx\.ingress\.kubernetes\.io/force-ssl-redirect"="false" \
  --set global.edition=ce \
  --timeout 600s \
  --namespace gitlab 2>&1

# Apply Traefik Ingress
kubectl apply -f ./confs/gitlab-traefik.yaml -n gitlab 2>&1

# Setup ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
wait_for_argo

# Create development namespace
kubectl create namespace dev

# Configure ArgoCD, with a custom refresh rate
kubectl -n argocd patch configmap argocd-cm --type merge  -p '{"data":{"repository.refresh": "60s"}}' 2>&1

# Apply ArgoCD application manifests
kubectl apply -n argocd -f ./confs/argo-app.yaml 2>&1

# Function to create GitLab repository
function create_gitlab_repo {
    
    local toolbox=$(kubectl get pod -n gitlab | grep toolbox | awk '{print $1}')

    if [[ $1 == token ]]; then
        kubectl exec -n gitlab -ti ${toolbox} -- \
        gitlab-rails runner -e production "
        user = User.find_by_username('root')
        token = user.personal_access_tokens.create!(
        scopes: [:api],
        name: 'cli-token-test',
        expires_at: Date.today + 7
        )
        token.set_token('my-token-cli')
        token.save!
        puts token.token
        " 2>&1
    else
        log I "Skipping gitlab token creation"

    fi

    # Create GitLab project
    curl -s -X POST http://gitlab.localhost/api/v4/projects -H "Host: gitlab.localhost" -H "PRIVATE-TOKEN: my-token-cli" -d "name=test-repo"

    # Make it public
    curl -s -X PUT "http://gitlab.localhost/api/v4/projects/$(curl -s -H "PRIVATE-TOKEN: my-token-cli" "http://gitlab.localhost/api/v4/projects" | jq -r '.[] | select(.name=="test-repo") | .id')"      -H "PRIVATE-TOKEN: my-token-cli"      -F "visibility=public"

    # Clone the p3 app repo
    git clone https://github.com/Ycaro02/IOT-app /tmp/github_app 2>&1

    # Clone the new GitLab repository
    git clone http://oauth2:my-token-cli@gitlab.localhost/root/test-repo /tmp/gitlab_repo 2>&1

    # Copy application manifests
    cp /tmp/github_app/app1.yaml /tmp/gitlab_repo

    # Commit and push changes
    cd /tmp/gitlab_repo
    git add . 2>&1
    git config --global user.email gitlab@iot.fr 2>&1
    git config --global user.name iot 2>&1
    git commit -m "Init gitlab repo" 2>&1
    git push 2>&1

    log I "GitLab repository 'test-repo' created and initialized."
}

# Wait for GitLab webservice pods to be running
until [ $(kubectl get pod -n gitlab | grep webservice | grep Running | grep "2/2" | wc -l) -eq 2 ]; do
    log I "Waiting for GitLab webservice pod to be running..."
    sleep 5
done

log I "GitLab webservice is running."

# Create GitLab repository
create_gitlab_repo token

# Add /etc/hosts entry
add_etc_hosts_entry "127.0.0.1" "will-app.com"

log I "GitLab setup completed. Access it at http://gitlab.localhost with username 'root' and the token created."

# Start watch command to monitor ArgoCD application status
watch "echo Waiting for argo app to be deployed, press Ctrl+C to stop this watch command; kubectl describe app -n argocd | tail"

# Check GitLab image version
log I "Gitlab image check"
GITLAB_VERSION=$(kubectl -n gitlab get pods -l app=webservice -o jsonpath="{.items[0].spec.containers[0].image}")

log I "Gitlab Version: ${GITLAB_VERSION}"

# Get GitLab root password
kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data}' | jq .password | tr -d '"' | base64 --decode > ~/.gitlab_pass
log I "Gitlab root password saved to ~/.gitlab_pass"


