#!/usr/bin/env fish

set PP $argv[1]
set COMPOSE_FILE $argv[2]

env PP="$PP" docker stack deploy --prune --compose-file "docker-stack$COMPOSE_FILE.yml" "robust$PP"

docker stack ps "robust$argv[1]"
