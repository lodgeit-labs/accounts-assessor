#!/usr/bin/env bash

docker swarm init
sudo apt install python3
python3 -m pip install --user -U click pyyaml
cp -r secrets_example secrets
cp -r sources/config_example sources/config
