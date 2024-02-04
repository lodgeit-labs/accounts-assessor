#!/usr/bin/env fish
function e; or status --is-interactive; or exit 1; end
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

set VENV_PATH ./venv
. $VENV_PATH/bin/activate.fish ;e

_ROBUST_COMPLETE=source_fish robust > ./venv/robust-complete.fish
