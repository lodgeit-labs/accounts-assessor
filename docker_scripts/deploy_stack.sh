#!/usr/bin/env fish

set PP $argv[1]
set INTERNAL_WORKERS_DOCKERFILE_CHOICE $argv[2]

env PP="$PP" docker stack deploy --prune --compose-file "docker-stack$INTERNAL_WORKERS_DOCKERFILE_CHOICE.yml" "robust$PP"

docker stack ps "robust$argv[1]"
