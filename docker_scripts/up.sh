#!/usr/bin/env fish

# rdf hackery2:fish/get_script_dir.fish
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

./up.py $argv
