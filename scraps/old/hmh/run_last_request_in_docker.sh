#!/usr/bin/env fish

# use this to run a request in docker, with g trace. internal services and rabbitmq have to be running.

xhost +local:docker

set SECRETS_DIR "(realpath ../secrets)"

docker run -it \
		--network="container:$argv[2]" \
		--mount source=robust$argv[1]_tmp,target=/app/server_root/tmp \
		--mount source=robust$argv[1]_cache,target=/app/cache \
		--volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
		--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
		--volume="SECRETS_DIR:/run/secrets" \
		--env="DISPLAY"	\
		--env="DETERMINANCY_CHECKER__USE__ENFORCER" \
		--entrypoint bash \
		"koo5/internal-workers$argv[1]:latest" \
		-c "cd /app/server_root/;  time env  PYTHONUNBUFFERED=1 CELERY_QUEUE_NAME=q7788 ../sources/internal_workers/invoke_rpc_cmdline.py --debug true --halt true -s \"http://localhost:7788\"  --prolog_flags \"set_prolog_flag(services_server,'http://services:17788')\" /app/server_root/tmp/last_request 2>&1 | less"




#--network=robust_robust_backend - this doesn't work, for some reason, unless you have the containers running on host network, you have to specify a running contaiiner's id

# Note: Docker secrets are only available to swarm services, not to standalone containers. To use this feature, consider adapting your container to run as a service. Stateful containers can typically run with a scale of 1 without changing the container code.
