#!/usr/bin/env bash

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"

sudo apt install python3 python3-pip docker fish apache2-utils

# for building and running containers
python3 -m pip install --user -U click pyyaml 

# for run_last_request_in_docker
python3 -m pip install --user -U docker 

cd ..
cp -r secrets_example secrets
cp -r sources/config_example sources/config

python3 setup.py install --user 

_ROBUST_COMPLETE=source_fish robust > ~/.config/fish/completions/robust-complete.fish


# optionally:
#docker swarm init

