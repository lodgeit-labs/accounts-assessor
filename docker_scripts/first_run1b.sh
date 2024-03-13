#!/usr/bin/env fish
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"
function e; or status --is-interactive; or exit 1; end
#function _old_fish_prompt; end; # https://github.com/python/cpython/issues/93858 ?


set VENV_PATH ./venv
python3 -m venv $VENV_PATH ;e
. $VENV_PATH/bin/activate.fish ;e

python3 -m pip install wheel
# (note we're not installing bindings here, we're installing docker-compose itself)
docker-compose version; or python3 -m pip install 'docker-compose>=1.29' 'docker==6.1.3' ;e

