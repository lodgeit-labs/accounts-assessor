#!/usr/bin/env fish

docker pull franzinc/agraph:v7.0.0

git status > static/docs/git_info.txt; and git log >> static/docs/git_info.txt;

and cp ../../secrets*.json .; and docker build --label  "koo5/internal-workers:latest"  -t "koo5/internal-workers" -f "internal_workers/Dockerfile" . ; 
and cp ../../secrets*.json .; and docker build --label  "koo5/internal-services:latest"  -t "koo5/internal-services" -f "internal_services/Dockerfile" . ; 
and cp ../../secrets*.json .; and docker build --label  "koo5/frontend-server:latest"  -t "koo5/frontend-server" -f "frontend_server/Dockerfile" . ; 
and echo "ok"

