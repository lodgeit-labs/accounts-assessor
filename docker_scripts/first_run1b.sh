#!/usr/bin/env fish
function _; or status --is-interactive; or exit 1; end

virtualenv -p /usr/bin/python3.10 venv ;_
. venv/bin/activate.fish ;_

# (note we're not installing bindings here, we're installing docker-compose itself)
docker-compose version; or python3 -m pip install 'docker-compose>=1.29'  ;_



