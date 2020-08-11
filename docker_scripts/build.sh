#!/usr/bin/env fish

docker pull franzinc/agraph:v7.0.0

git status > static/docs/git_info.txt; and git log >> static/docs/git_info.txt;

and set -x WHAT internal-workers;   
and cp ../../secrets*.json .; and docker build --label  "koo5/$WHAT:latest"  -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; 
and set -x WHAT internal-services;  
and cp ../../secrets*.json .; and docker build --label  "koo5/$WHAT:latest"  -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; 
and set -x WHAT frontend-server;    
and cp ../../secrets*.json .; and docker build --label  "koo5/$WHAT:latest"  -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; 
and echo "ok"

