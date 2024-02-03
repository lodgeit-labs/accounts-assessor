#!/usr/bin/env fish
function e; or status --is-interactive; or exit 1; end
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"
#function _old_fish_prompt; end; # https://github.com/python/cpython/issues/93858 ?

set VENV_PATH ./venv
. $VENV_PATH/bin/activate.fish ;e

python3 setup.py develop ;e

#mkdir -p ~/.config/fish/completions/
_ROBUST_COMPLETE=source_fish robust > ./venv/robust-complete.fish
#. ~/.config/fish/completions/robust-complete.fish
./init_configs.sh
