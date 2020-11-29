#!/usr/bin/env fish

set PP $argv[1]

docker service logs -f robust"$PP"_agraph  &
docker service logs -f robust"$PP"_frontend-server  &
docker service logs -f robust"$PP"_internal-workers &
docker service logs -f robust"$PP"_internal-services


