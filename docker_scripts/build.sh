#!/usr/bin/env fish

set PP $argv[1]
set INTERNAL_WORKERS_DOCKERFILE_CHOICE $argv[2]

docker pull franzinc/agraph:v7.0.0

git status > static/docs/git_info.txt; and git log >> static/docs/git_info.txt;

and cp ../../secrets*.json .; 

and docker build -t  "koo5/internal-workers$PP"   -f "internal_workers/Dockerfile$INTERNAL_WORKERS_DOCKERFILE_CHOICE" . ; 
and docker build -t  "koo5/internal-services$PP"  -f "internal_services/Dockerfile" . ; 
and docker build -t  "koo5/frontend-server$PP"    -f "frontend_server/Dockerfile" . ; 

and echo "ok"

