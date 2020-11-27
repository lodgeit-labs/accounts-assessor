#!/usr/bin/env fish

docker stack deploy --prune --compose-file docker-stack.yml robust

docker stack ps robust

