#!/usr/bin/env fish

docker service logs -f robust_agraph  &
docker service logs -f robust_frontend-server  &
docker service logs -f robust_internal-workers &
docker service logs -f robust_internal-services


