#!/usr/bin/env fish

# rdf hackery2:fish/get_script_dir.fish
set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"/../sources/

# rdf docker:PP
set PP $argv[1]

# rdf <docker:INTERNAL_WORKERS_DOCKERFILE_CHOICE>
set MODE $argv[2]


# rdf koo:notes:agraph
#docker pull franzinc/agraph:v7.0.0


../docker_scripts/git_info.fish


and echo "";
and echo "flower...";
and docker build -t  "koo5/flower$PP"             -f "../docker_scripts/flower/Dockerfile" . ; 
and echo "";
and echo "apache...";
and docker build -t  "koo5/apache$PP"             -f "../docker_scripts/apache/Dockerfile" . ; 
and echo "";
and echo "agraph...";
and docker build -t  "koo5/agraph$PP"             -f "../docker_scripts/agraph/Dockerfile" . ; 
and echo "";
and echo "internal-workers...";
and docker build -t  "koo5/internal-workers$PP"   -f "internal_workers/Dockerfile$MODE" . ; 
and echo "";
and echo "internal-services...";
and docker build -t  "koo5/internal-services$PP"  -f "internal_services/Dockerfile$MODE" . ; 
and echo "";
and echo "frontend-server...";
and docker build -t  "koo5/frontend-server$PP"    -f "frontend_server/Dockerfile$MODE" . ; 

and echo "ok"

