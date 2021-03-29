#!/usr/bin/env fish

set PP $argv[1]

docker service logs -f robust"$PP"_flower  &
docker service logs -f robust"$PP"_apache  &
docker service logs -f robust"$PP"_frontend-server  &
docker service logs -f robust"$PP"_internal-workers &
docker service logs -f robust"$PP"_internal-services


