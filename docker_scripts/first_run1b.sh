#!/usr/bin/env fish

# for the building and running UI
python3 -m pip install --user click pyyaml 

# (note we're not installing some bindings here, we're installing docker-compose itself)
# python3 -m pip install --user docker-compose

# for run_last_request_in_docker (these are bindings)
python3 -m pip install --user docker 

# for nice building UI
python3 -m pip install --user libtmux fire

