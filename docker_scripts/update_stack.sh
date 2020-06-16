#!/usr/bin/env fish


docker service update --force robust_frontend_server
docker service update --force robust_internal_services
docker service update --force robust_internal_workers


