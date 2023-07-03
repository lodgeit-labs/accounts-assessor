#!/usr/bin/env fish
function _; or status --is-interactive; or exit 1; end

virtualenv -p /usr/bin/python3.10 venv
. venv/bin/activate.fish

# for the building and running UI
# docker for run_last_request_in_docker (these are bindings)
python3 -m pip install --user "click>=8" pyyaml virtualenv libtmux docker ;_
# (note we're not installing bindings here, we're installing docker-compose itself)
docker-compose version; or python3 -m pip install --user 'docker-compose>=1.29'  ;_



