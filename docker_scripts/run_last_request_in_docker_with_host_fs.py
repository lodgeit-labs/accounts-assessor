#!/usr/bin/env python3




import shlex, subprocess, logging, os
try:
	import click
except:
	print('please install:\npython3 -m pip install --user -U click')
	exit(1)



def flatten_lists(x):
	if isinstance(x, list):
		r = []
		for y in x:
			z = flatten_lists(y)
			if isinstance(z, list):
				r += z
			else:
				r.append(z)
		return r
	else:
		return x



sq = shlex.quote



def co(cmd):
	return subprocess.check_output(cmd, text=True, universal_newlines=True)
def cc(cmd):
	return subprocess.check_call(cmd, text=True, universal_newlines=True)
ss = shlex.split


def realpath(x):
	return co(['realpath', x])[:-1]





l = logging.getLogger()


l.setLevel(logging.DEBUG)
l.addHandler(logging.StreamHandler())


@click.command(
	help="""Run a request by attaching an internal-workers-hollow container to a deployed robust docker stack.""",
	context_settings=dict(help_option_names=['-h', '--help'],
						  show_default=True)
	)

@click.option('-pp', '--port_postfix', 			type=str, 	default='',
	help="last two or more digits of the services' public ports, identifies the particular docker stack.")

@click.option('-pu', '--server_public_url', 	type=str, 	default=None,
	help="The public-facing server url, default http://localhost:88{port_postfix}.")

@click.option('-d', '--debug', 	type=bool, 	default=True,
	help="debug, default True.")

@click.option('-r', '--request', 				type=str, 	default='/app/server_root/tmp/last_request',
	help="the directory containing the request file(s).")

@click.option('-s', '--script', 				type=str,
	help="override what to run inside the container")

@click.option('-dr', '--dry_run', type=bool, default=False, help="stop before invoking swipl")




def run(port_postfix, server_public_url, debug, request, script, dry_run):
	if os.environ.get('DISPLAY','') != '':
		cc(['./lib/xhost.py'])
	cc(['./lib/git_info.fish'])

	HOME = realpath('~')
	SECRETS_DIR  = realpath('../secrets')
	RUNNING_CONTAINER_ID = co(['./lib/get_id_of_running_container.py', '-pp', port_postfix])[:-1]
	STACK = 'robust' + port_postfix
	
	l.debug(f'attaching to network of RUNNING_CONTAINER_ID : {RUNNING_CONTAINER_ID}')

	if debug:
		DBG1 = "--debug true"
		DBG2 = "debug,debug(gtrace(source)),debug(gtrace(position))"
#		DBG3 = '--env="SWIPL_NODEBUG"'
	else:
		DBG1 = "--debug false"
		DBG2 = 'true'
#		DBG3 = ''

	if not server_public_url:
		server_public_url = f"http://localhost:88{port_postfix}"

	if script == None:
		script = f""" \
					cd /app/server_root/tmp; \
					env PYTHONUNBUFFERED=1  \
					/app/sources/workers/invoke_rpc_cmdline.py \
					{DBG1} \
					--halt true \
					--dry_run {dry_run} \
					-s "{server_public_url}" \
					--prolog_flags "{DBG2},set_prolog_flag(services_server,'http://services:17788')" \
					{sq(request)} \
					2>&1 | tee /app/server_root/tmp/out"""

	cmd = ss('docker run -it') + [
		f'--network=container:{RUNNING_CONTAINER_ID}',
		'--mount', f'source={STACK}_tmp,target=/app/server_root/tmp',
		'--mount', f'source={STACK}_cache,target=/app/cache',
		'--mount', 'type=bind,source=' + realpath('../sources')+',target=/app/sources',
		'--mount', 'type=bind,source=' + realpath('../tests') + ',target=/app/tests',
		'--mount', 'type=bind,source='+realpath('../sources/swipl/xpce')+',target=/root/.config/swi-prolog/xpce',
		] + (
		ss(f"""
			--volume="{HOME}/.Xauthority:/root/.Xauthority:rw" \
			--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
			--volume="{SECRETS_DIR}:/run/secrets" \
	\
			--env="DISPLAY"	\
			--env="DETERMINANCY_CHECKER__USE__ENFORCER" \
			--env="ROBUST_DOC_ENABLE_TRAIL" \
			--env="ROBUST_ROL_ENABLE_CHECKS" \
			--env="ENABLE_CONTEXT_TRACE_TRAIL" \
			--env="ROBUST_ENABLE_NICETY_REPORTS" \
			--env="REDIS_HOST" \
			--env="RABBITMQ_URL" \
			--env="REMOULADE_PG_URI" \

	\
			--env SECRET__CELERY_BROKER_URL="amqp://guest:guest@rabbitmq:5672//" \
			--entrypoint bash
		""")
		) + [
			f"koo5/workers-hlw{port_postfix}:latest",
			'-c', script
		]


	cmd = flatten_lists(cmd)
	#print(cmd)
	cc(cmd)

if __name__ == '__main__':
	run()


 #todo instead? https://github.com/docker/compose/issues/3012#issuecomment-219543906