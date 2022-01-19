#!/usr/bin/env fish

# rdf hackery2:fish/get_script_dir.fish
set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"/../../sources/

../docker_scripts/lib/_run.py build $argv
