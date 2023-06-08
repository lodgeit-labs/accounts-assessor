#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"


cat ~/robust_first_run_v1_done.flag; and exit 0
touch robust_first_run_v1_done.flag


sudo apt install -y python3 python3-pip

# not sure if still needed, maybe was only used for generating password file?
#sudo apt install apache2-utils

# sorry, i do a lot of small scripting with it, as it's my daily shell. But it shouldn't be hard to get by without it, if necessary
sudo apt install -y fish 

# for nice building UI
sudo apt install -y tmux

# you'll definitely need docker obtained one way or another
which docker; or sudo apt install docker.io golang-docker-credential-helpers

# compose is a tad more suitable for development than swarm 
which docker-compose; or sudo apt install -y docker-compose

# for the building and running UI
python3 -m pip install --user click pyyaml 

# (note we're not installing some bindings here, we're installing docker-compose itself)
# python3 -m pip install --user docker-compose

# for run_last_request_in_docker (these are bindings)
python3 -m pip install --user docker 

# for nice building UI
python3 -m pip install --user libtmux fire

# if not using compose:
#docker swarm init

