#!/usr/bin/env fish


docker service update --force robust_frontend-server
docker service update --force robust_internal-services
docker service update --force robust_internal-workers


