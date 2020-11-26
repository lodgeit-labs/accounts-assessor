#!/usr/bin/env fish

# use this to run a request in docker, with g trace. internal services and rabbitmq have to be running.

xhost +local:docker

docker run -it \
		--network="host" \
		--mount source=robust_tmp,target=/app/server_root/tmp \
		--mount source=robust_cache,target=/app/cache \
		--mount type=bind,source=(realpath ../sources),target=/app/sources \
		--volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
		--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
		--env="DISPLAY"	\
		--env="DETERMINANCY_CHECKER__USE__ENFORCER" \
		--entrypoint bash \
		"koo5/internal-workers-dev:latest" \
		-c "cd /app/server_root/;  time env AGRAPH_SECRET_PORT=10036 AGRAPH_SECRET_HOST=localhost  PYTHONUNBUFFERED=1 CELERY_QUEUE_NAME=q7788 ../sources/internal_workers/invoke_rpc_cmdline.py --debug true --halt true -s \"http://localhost:7788\"  --prolog_flags \"set_prolog_flag(services_server,'http://localhost:17788')\" /app/server_root/tmp/last_request 2>&1 | less"


#--network=robust_robust_backend - this doesn't work, for some reason, unless you have the containers running on host network, you have to specify a running contaiiner's id
