#!/usr/bin/env fish

# use this to run a request in docker, with g trace. internal services and rabbitmq have to be running.

xhost +local:docker


docker run -it \
		--network="container:$argv" \
		--mount source=robust_my-vol,target=/app/server_root/tmp \
		--mount source=robust_cache,target=/app/cache \
		--volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
		--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
		--env="DISPLAY"	\
		--env="DETERMINANCY_CHECKER__USE__ENFORCER" \
		--entrypoint bash \
		"koo5/internal-workers:latest" \
		-c "cd /app/server_root/;  time env  PYTHONUNBUFFERED=1 CELERY_QUEUE_NAME=q7788 ../sources/internal_workers/invoke_rpc_cmdline.py --debug true --halt true -s \"http://localhost:7788\"  --prolog_flags \"set_prolog_flag(services_server,'http://internal-services:17788'),set_prolog_flag(die_on_error,true)\" /app/server_root/tmp/last_request 2>&1 | less"




#--network=robust_robust_backend 
