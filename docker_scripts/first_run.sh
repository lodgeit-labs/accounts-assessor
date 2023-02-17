#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"

sudo apt install python3 python3-pip docker fish apache2-utils

# for building and running containers
python3 -m pip install click pyyaml 

# for run_last_request_in_docker
python3 -m pip install docker 

python3 setup.py develop 

_ROBUST_COMPLETE=source_fish robust > ~/.config/fish/completions/robust-complete.fish


# optionally:
#docker swarm init

