#!/usr/bin/env fish

# use this to run a request in docker, with g trace. internal services and rabbitmq have to be running.
# you need this to run a request with an image built to bind sources dir

xhost +local:docker


set SECRETS_DIR (realpath ../secrets)
set RUNNING_CONTAINER_ID (./get_id_of_running_container.py -pp $argv[1])
#set LESSS "2>&1 | less"

docker run -it \
#		--network="robust$argv[1]_backend"
# ^ should work if "attachable" works
		--network="container:$RUNNING_CONTAINER_ID" \
		--mount source=robust$argv[1]_tmp,target=/app/server_root/tmp \
		--mount source=robust$argv[1]_cache,target=/app/cache \
		--mount type=bind,source=(realpath ../sources),target=/app/sources \
		--mount type=bind,source=(realpath ../sources/swipl/xpce),target=/root/.config/swi-prolog/xpce \
		--volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
		--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
		--volume="$SECRETS_DIR:/run/secrets" \
		--env="DISPLAY"	\
		--env="DETERMINANCY_CHECKER__USE__ENFORCER" \
		--entrypoint bash \
#		--publish 1234:1234 \
		"koo5/internal-workers$argv[1]:latest" \
#		-c bash
		-c "cd /app/server_root/;  time env  PYTHONUNBUFFERED=1 CELERY_QUEUE_NAME=q7788 ../sources/internal_workers/invoke_rpc_cmdline.py --debug true --halt true -s \"http://localhost:77$argv[1]\"  --prolog_flags \"debug,set_prolog_flag(services_server,'http://internal-services:17788')$argv[2]\" /app/server_root/tmp/last_request $LESSS"


# AGRAPH_SECRET_PORT=10036 AGRAPH_SECRET_HOST=localhost 
#--network=robust_robust_backend - this doesn't work, for some reason, unless you have the containers running on host network, you have to specify a running container's id
