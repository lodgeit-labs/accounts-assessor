#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

# finally, the building/running script itself. And no, there probably isnt that much reason for it not to be runnable without installation. I think it was for shell autocomplete.
function _old_fish_prompt; end; # https://github.com/python/cpython/issues/93858 ?
. venv/bin/activate.fish
python3 setup.py develop ;_

#if [ "$CI" = "true" ]
#  python3 setup.py install --user;_
#else
#  python3 setup.py develop --user;_
#end

mkdir -p ~/.config/fish/completions/
_ROBUST_COMPLETE=source_fish robust > ~/.config/fish/completions/robust-complete.fish

./init_configs.sh
