#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)));cd "$DIR"
. venv/bin/activate.fish ;_

robust run --mount_host_sources_dir true  -d1 true --enable_public_gateway false --enable_public_insecure true --use_host_network 1 --parallel_build 0 --rm_stack 1 --compose 1  --secrets_dir ../secrets/ $argv
