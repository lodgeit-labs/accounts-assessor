#!/usr/bin/env fish
function _; or status --is-interactive; or exit 1; end

# for the building and running UI
python3 -m pip install --user click pyyaml;_
# (note we're not installing bindings here, we're installing docker-compose itself)
# python3 -m pip install --user docker-compose;_
# for run_last_request_in_docker (these are bindings)
python3 -m pip install --user docker;_
# for nice building UI
python3 -m pip install --user libtmux fire;_

