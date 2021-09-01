#!/usr/bin/env fish


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
		#--mount type=bind,source=(realpath ../sources/swipl/xpce),target=/root/.config/swi-prolog/xpce \
		--volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
		--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
		--volume="$SECRETS_DIR:/run/secrets" \
		--env="DISPLAY"	\
		--env="DETERMINANCY_CHECKER__USE__ENFORCER" \
		--env SECRET__CELERY_BROKER_URL="amqp://guest:guest@rabbitmq:5672//" \
		--entrypoint bash \
		"koo5/internal-workers$argv[1]:latest" \
		-c "cd /app/server_root/; swipl ../sources/lib/rpc_server.pl"




# (debug,set_prolog_flag(debug,true),set_prolog_flag(gtrace,false),debug,set_prolog_flag(services_server,'http://internal-services:17788'),lib:process_request_rpc_cmdline_json_text('{\"method\": \"calculator\", \"params\": {\"server_url\": \"http://localhost:7755\", \"request_files\": [\"/app/server_root/tmp/last_request/lodgeitrequest.n3\"], \"request_tmp_directory_name\": \"1609180107.315197.8.1.2E9F16Cx7480\", \"result_tmp_directory_name\": \"1609180107.315197.8.3.2E9F16Cx7500_2\", \"request_uri\": \"http://dev-node.uksouth.cloudapp.azure.com/rdf/requests/1609180107.315197.8.3.2E9F16Cx7500\", \"rdf_namespace_base\": \"http://dev-node.uksouth.cloudapp.azure.com/rdf/\", \"rdf_explorer_bases\": [\"http://dev-node.uksouth.cloudapp.azure.com:10036/#/repositories/a/node/\"]}}'),halt,halt(0));halt(1).
