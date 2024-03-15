#!/usr/bin/env bash


set -x
set -e

#https://docs.docker.com/compose/install/linux/#install-the-plugin-manually

 DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}

 mkdir -p $DOCKER_CONFIG/cli-plugins

 curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

 chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
 
 docker compose version
 