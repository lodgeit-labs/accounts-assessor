#!/usr/bin/env fish

set PP $argv[1]

docker service logs -f robust"$PP"_redis  &
docker service logs -f robust"$PP"_caddy  &
docker service logs -f robust"$PP"_apache  &
docker service logs -f robust"$PP"_frontend  &
docker service logs -f robust"$PP"_workers &
docker service logs -f robust"$PP"_services
docker service logs -f robust"$PP"_actors



