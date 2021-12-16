#!/usr/bin/env fish

set DIR (dirname (readlink -m (status --current-filename)))
cd "$DIR"


set PP $argv[1]

docker service logs -f robust"$PP"_agraph  &
./follow_logs_noagraph.sh $argv
