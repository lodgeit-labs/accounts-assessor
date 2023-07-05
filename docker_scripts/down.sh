#!/usr/bin/env fish

function _; or status --is-interactive; or exit 1; end

# rdf hackery2:fish/get_script_dir.fish
set DIR (dirname (readlink -m (status --current-filename))); cd "$DIR"

. venv/bin/activate.fish ;_

docker_scripts/venv/bin/docker-compose  -f generated_stack_files/last.yml -p robust --compatibility down
