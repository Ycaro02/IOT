#!/bin/bash

ssh-copy-id -p 2222 iot@127.0.0.1 2>/dev/null

scp -i ~/.ssh/ez_iot -P 2222 ./gitlab_install.sh iot@127.0.0.1:/home/iot/new_test.sh

ssh -i ~/.ssh/ez_iot -p 2222 iot@127.0.0.1 /home/iot/new_test.sh
ssh -i ~/.ssh/ez_iot -p 2222 iot@127.0.0.1 /home/iot/new_test.sh