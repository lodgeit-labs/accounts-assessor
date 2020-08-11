#!/usr/bin/env fish

docker pull franzinc/agraph:v7.0.0

git status > static/docs/git_info.txt; and git log >> static/docs/git_info.txt

set -x WHAT internal_workers;   and cp ../../secrets*.json .; and docker build --label  "koo5/$WHAT:latest"  -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; and \
set -x WHAT internal_services;  and cp ../../secrets*.json .; and docker build --label  "koo5/$WHAT:latest"  -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; and \
set -x WHAT frontend_server;    and cp ../../secrets*.json .; and docker build --label  "koo5/$WHAT:latest"  -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; and echo "ok"

