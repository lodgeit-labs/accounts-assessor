#!/usr/bin/env fish
function _; or status --is-interactive; or exit 1; end
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"
set VENV_PATH ~/.local/robust/$DIR/venv
. $VENV_PATH/bin/activate.fish ;_

docker-compose  -f ../generated_stack_files/last.yml -p robust --compatibility down
