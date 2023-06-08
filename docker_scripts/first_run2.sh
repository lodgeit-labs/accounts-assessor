#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"

# finally, the building/running script itself. And no, there probably isnt that much reason for it not to be runnable without installation
python3 setup.py develop --user

_ROBUST_COMPLETE=source_fish robust > ~/.config/fish/completions/robust-complete.fish
`                                 

cd ..
cp -r secrets_example secrets
cp -r sources/config_example sources/config
