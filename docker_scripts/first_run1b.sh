#!/usr/bin/env fish
function _; or status --is-interactive; or exit 1; end

# for the building and running UI
python3 -m pip install --user "click>=8" pyyaml  ;_
# (note we're not installing bindings here, we're installing docker-compose itself)
docker-compose version; or python3 -m pip install --user docker-compose>=1.29  ;_
# for run_last_request_in_docker (these are bindings)
python3 -m pip install --user docker  ;_
# for "nice" deployment log following
python3 -m pip install --user libtmux fire  ;_

