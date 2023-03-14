#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"

sudo apt install python3 python3-pip docker fish apache2-utils tmux 

# for building and running containers
python3 -m pip install --user click pyyaml 

# for run_last_request_in_docker
python3 -m pip install --user docker 

# for nice building UI
python3 -m pip install --user libtmux

python3 setup.py develop --user

_ROBUST_COMPLETE=source_fish robust > ~/.config/fish/completions/robust-complete.fish


# optionally:
#docker swarm init

