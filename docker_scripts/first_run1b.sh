#!/usr/bin/env fish
function _; or status --is-interactive; or exit 1; end

python3 -m venv venv ;_
function _old_fish_prompt; end; # https://github.com/python/cpython/issues/93858 ?
. venv/bin/activate.fish ;_

# (note we're not installing bindings here, we're installing docker-compose itself)
docker-compose version; or python3 -m pip install 'docker-compose>=1.29'  ;_

