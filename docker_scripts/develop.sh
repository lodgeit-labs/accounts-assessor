#!/usr/bin/env fish

#function _old_fish_prompt; end; # https://github.com/python/cpython/issues/93858 ? 

function e; or status --is-interactive; or exit 1; end

set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

set VENV_PATH ./venv
. $VENV_PATH/bin/activate.fish ;e

ulimit -n 50000

PYTHONUNBUFFERED=true robust run --mount_host_sources_dir true  --enable_public_gateway false --enable_public_insecure true --use_host_network 1 --rm_stack 1 --compose 1 --secrets_dir ../secrets/ $argv
