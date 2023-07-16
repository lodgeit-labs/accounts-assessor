#!/usr/bin/env fish

function _; or status --is-interactive; or exit 1; end

# rdf hackery2:fish/get_script_dir.fish
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"
function _old_fish_prompt; end; # https://github.com/python/cpython/issues/93858 ?

./first_run.sh
. venv/bin/activate.fish ;_
PYTHONUNBUFFERED=true ./up.py $argv
