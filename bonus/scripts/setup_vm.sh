#!/bin/bash

#ssh-copy-id -p 2222 iot@127.0.0.1 2>/dev/null

# ssh -i ~/.ssh/ez_iot -p 2222 iot@127.0.0.1 'bash -c "curl -s localhost -H \"host: will-app.com\""'

git clone git@vogsphere.42angouleme.fr:vogsphere/intra-uuid-0fa8c839-0b9a-44a7-8895-824130860b25-7123585-nfour /tmp/intra
scp -r -i ~/.ssh/ez_iot -P 2222 /tmp/intra iot@127.0.0.1:/home/iot/intra
rm -rf /tmp/intra
# ssh -i ~/.ssh/ez_iot -p 2222 iot@127.0.0.1 "cd /home/iot/intra/bonus && ./sh/gitlab_install.sh"


