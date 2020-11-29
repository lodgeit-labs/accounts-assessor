#!/usr/bin/env fish

# rdf://hackery2:fish/get_script_dir.fish
set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"/../sources/

# rdf://docker:PP
set PP $argv[1]

# see <docker:INTERNAL_WORKERS_DOCKERFILE_CHOICE>
set INTERNAL_WORKERS_DOCKERFILE_CHOICE $argv[2]

docker pull franzinc/agraph:v7.0.0

git status > static/docs/git_info.txt; and git log >> static/docs/git_info.txt;

and docker build -t  "koo5/internal-workers$PP"   -f "internal_workers/Dockerfile$INTERNAL_WORKERS_DOCKERFILE_CHOICE" . ; 
and docker build -t  "koo5/internal-services$PP"  -f "internal_services/Dockerfile" . ; 
and docker build -t  "koo5/frontend-server$PP"    -f "frontend_server/Dockerfile" . ; 

and echo "ok"

