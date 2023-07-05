#!/usr/bin/env fish

function _; or status --is-interactive; or exit 1; end

# rdf hackery2:fish/get_script_dir.fish
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"
function _old_fish_prompt; end; # https://github.com/python/cpython/issues/93858 ?
. venv/bin/activate.fish ;_

./up.py $argv
