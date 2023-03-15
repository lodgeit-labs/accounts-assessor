#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"

sudo apt install python3 python3-pip 

# not sure if still needed, maybe was only used for generating password file?
sudo apt install apache2-utils 

# sorry, i do a lot of small scripting with it, as it's my daily shell. But it shouldn't be hard to get by without it, if necessary
sudo apt install fish 

# for nice building UI
tmux

# you'll definitely need docker obtained one way or another
sudo apt install docker.io golang-docker-credential-helpers

# compose is a tad more suitable for development than swarm 
sudo apt install docker-compose

# for the building and running UI
python3 -m pip install --user click pyyaml 

# (note we're not installing some bindings here, we're installing docker-compose itself)
# python3 -m pip install --user docker-compose

# for run_last_request_in_docker (these are bindings)
python3 -m pip install --user docker 

# for nice building UI
python3 -m pip install --user libtmux fire

# finally, the building/running script itself. And no, there probably isnt that much reason for it not to be runnable without installation
python3 setup.py develop --user

_ROBUST_COMPLETE=source_fish robust > ~/.config/fish/completions/robust-complete.fish


# if not using compose:
#docker swarm init

