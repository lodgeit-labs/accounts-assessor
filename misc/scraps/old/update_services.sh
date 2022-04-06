#!/usr/bin/env fish


docker service update --force robust_frontend
docker service update --force robust_services
docker service update --force robust_workers


