#!/usr/bin/env bash

sudo apt install python3 docker
docker swarm init


python3 -m pip install --user -U click pyyaml # for building and running containers
python3 -m pip install --user -U docker # for run_last_request_in_docker

cp -r secrets_example secrets
cp -r sources/config_example sources/config
