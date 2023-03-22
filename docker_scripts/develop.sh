#!/usr/bin/env fish

robust run --mount_host_sources_dir true --enable_public_gateway false -d1  true --enable_public_insecure true  --port_postfix '' --use_host_network 1 --parallel_build 0 --rm_stack 1 --compose 1  --secrets_dir ../secrets/ $argv
