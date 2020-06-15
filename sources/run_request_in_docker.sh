#!/usr/bin/env fish

# use this to run a request in docker, with gtrace. internal services and rabbitmq have to be running.

xhost +local:docker

#set -x WHAT internal_workers;  cp ../../secrets*.json .;  git status > git_info.txt; git log >> git_info.txt; docker build -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; and docker run -it  --mount source=robust_my-vol,target=/app/server_root/tmp  --volume="$HOME/.Xauthority:/root/.Xauthority:rw" --env="DISPLAY"  --net=host  --entrypoint bash "koo5/$WHAT" -c "reset;echo -e \"\e[3J\"; cd /app/server_root/;  time env  PYTHONUNBUFFERED=1 CELERY_QUEUE_NAME=q7788 ../internal_workers/invoke_rpc_cmdline.py --debug true --halt true -s \"http://localhost:7788\"  --prolog_flags \"set_prolog_flag(services_server,'http://localhost:17788'),set_prolog_flag(die_on_error,true)\" /app/server_root/tmp/last_request"

docker run -it --network=robust_backend --mount source=robust_my-vol,target=/app/server_root/tmp  --volume="$HOME/.Xauthority:/root/.Xauthority:rw" --env="DISPLAY" --entrypoint bash "koo5/$WHAT" -c "cd /app/server_root/;  time env  PYTHONUNBUFFERED=1 CELERY_QUEUE_NAME=q7788 ../internal_workers/invoke_rpc_cmdline.py --debug true --halt true -s \"http://localhost:7788\"  --prolog_flags \"set_prolog_flag(services_server,'http://internal-services:17788'),set_prolog_flag(die_on_error,true)\" /app/server_root/tmp/last_request 2>&1 | less"

# used like this: set -x WHAT internal_workers;  cp ../../secrets*.json .;  git status > git_info.txt; git log >> git_info.txt; docker build -t "koo5/$WHAT" -f "$WHAT/Dockerfile" . ; and reset; and echo -e "\e[3J"; and  ./run_request_in_docker.sh
