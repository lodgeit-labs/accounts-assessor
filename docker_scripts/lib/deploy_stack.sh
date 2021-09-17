#!/usr/bin/env fish

set PP $argv[1]
set COMPOSE_FILE $argv[2]
set -x DJANGO_ARGS $argv[3]

./lib/git_info.fish

env PP="$PP" docker stack deploy --prune --compose-file "$COMPOSE_FILE" "robust$PP"

