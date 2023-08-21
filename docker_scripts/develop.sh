#!/usr/bin/env fish
set DIR (dirname (readlink -m (status --current-filename)));cd "$DIR"
function _old_fish_prompt; end; # https://github.com/python/cpython/issues/93858 ? 

set VENV_PATH ~/.local/robust/$DIR/venv
. $VENV_PATH/bin/activate.fish ;_

PYTHONUNBUFFERED=true robust run --mount_host_sources_dir true  --enable_public_gateway false --enable_public_insecure true --use_host_network 1 --parallel_build 0 --rm_stack 1 --compose 1  --secrets_dir ../secrets/ $argv
