#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"

sudo apt install python3 python3-pip docker fish apache2-utils tmux 

# for the building and running UI
python3 -m pip install --user click pyyaml 

# compose is a tad more suitable for development than swarm (note we're not installing some bindings here, we're installing docker-compose itself)
python3 -m pip install --user docker-compose

# for run_last_request_in_docker (these are bindings)
python3 -m pip install --user docker 

# for nice building UI
python3 -m pip install --user libtmux

python3 setup.py develop --user

_ROBUST_COMPLETE=source_fish robust > ~/.config/fish/completions/robust-complete.fish


# optionally:
#docker swarm init

