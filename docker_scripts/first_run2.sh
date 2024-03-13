#!/usr/bin/env fish
function e; or status --is-interactive; or exit 1; end
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

set VENV_PATH ./venv
. $VENV_PATH/bin/activate.fish ;e

python3 setup.py develop ;e

./init_configs.sh
