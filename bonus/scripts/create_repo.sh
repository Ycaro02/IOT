#!/bin/bash


TOOLBOX=$(kubectl get pod -n gitlab | grep toolbox | awk '{print $1}')

if [[ $1 == token ]]; then

kubectl exec -n gitlab -ti ${TOOLBOX} -- \
gitlab-rails runner -e production "
user = User.find_by_username('root')
token = user.personal_access_tokens.create!(
  scopes: [:api],
  name: 'cli-token-test',
  expires_at: Date.today + 7
)
token.set_token('mon-token-cli')
token.save!
puts token.token
"
else
	echo skip token creation

fi

curl -X POST http://gitlab.localhost/api/v4/projects -H "Host: gitlab.localhost" -H "PRIVATE-TOKEN: mon-token-cli-test" -d "name=test-repo"

curl -X PUT "http://gitlab.localhost/api/v4/projects/$(curl -s -H "PRIVATE-TOKEN: mon-token-cli" "http://gitlab.localhost/api/v4/projects" | jq -r '.[] | select(.name=="test-repo") | .id')"      -H "PRIVATE-TOKEN: mon-token-cli"      -F "visibility=public"


rm -rf /tmp/gitlab_repo /tmp/github_app

git clone https://github.com/Ycaro02/IOT-app /tmp/github_app
git clone http://oauth2:mon-token-cli@gitlab.localhost/root/test-repo /tmp/gitlab_repo


cp /tmp/github_app/app1.yaml /tmp/gitlab_repo

cd /tmp/gitlab_repo
git add .
git config --global user.email gitlab@iot.fr
git config --global user.name iot
git commit -m "Init gitlab repo"
git push

