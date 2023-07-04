#!/usr/bin/env fish

function _; or status --is-interactive; or exit 1; end

# rdf hackery2:fish/get_script_dir.fish
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

. venv/bin/activate.fish ;_

./up.py $argv
