#!/usr/bin/env fish


env PP="$argv[1]" docker stack deploy --prune --compose-file docker-stack.yml "robust$argv[1]"

docker stack ps "robust$argv[1]"
