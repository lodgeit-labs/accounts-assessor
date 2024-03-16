#!/usr/bin/env fish
function e; or status --is-interactive; or exit 1; end
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

set VENV_PATH ./venv
python3 -m venv $VENV_PATH ;e
. $VENV_PATH/bin/activate.fish ;e
ython3 -m pip install wheel
python3 setup.py develop ;e

