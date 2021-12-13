#!/usr/bin/env python3.9


try:
	import click
except:
	print('please install:\npython3.9 -m pip install --user -U click')
	exit(1)

import os,subprocess,time,shlex,logging




l = logging.getLogger()


l.setLevel(logging.DEBUG)
l.addHandler(logging.StreamHandler())


sq = shlex.quote
ss = shlex.split



def co(cmd):
	return subprocess.check_output(cmd, text=True, universal_newlines=True)
def cc(cmd):
	return subprocess.check_call(cmd, text=True, universal_newlines=True)

def ccss(cmd):
	return cc(ss(cmd))


threads = []


def task(cmd):
	if _parallel:
		from threading import Thread
		thread = Thread(target = ccss, args = (cmd,))
		threads.append(thread)
		thread.start()
	else:
		ccss(cmd)


def realpath(x):
	return co(['realpath', x])[:-1]



@click.command(help="""build the docker images.""")

@click.option('-pp', '--port_postfix', 				type=str, 	default='', 
	help="last two or more digits of the services' public ports. Also identifies the particular docker stack.")

@click.option('-m', '--mode', 				type=str, 	default='full', 
	help="hollow or full images? mount host directories containing source code or copy everything into image?")

@click.option('-p', '--parallel', 			type=bool, 	default=False,
	help="build docker images in parallel?")

def run(port_postfix, mode, parallel):
	global _parallel
	_parallel=parallel

	cc('../docker_scripts/lib/git_info.fish')

	print()
	print("flower...")
	task(f'docker build -t  "koo5/flower{port_postfix}"             -f "../docker_scripts/flower/Dockerfile" . ')
	
	print()
	print("apache...")
	task(f'docker build -t  "koo5/apache{port_postfix}"             -f "../docker_scripts/apache/Dockerfile" . ')

	print()
	print("agraph...")
	task(f'docker build -t  "koo5/agraph{port_postfix}"             -f "../docker_scripts/agraph/Dockerfile" . ')

	print()
	print("internal-workers-hlw...")
	task(f'docker build -t  "koo5/workers-hlw{port_postfix}"   -f "internal_workers/Dockerfile_hollow" . ')

	print()
	print("internal-services-hollow...")
	task(f'docker build -t  "koo5/services-hlw{port_postfix}"  -f "internal_services/Dockerfile_hollow" . ')

	print()
	print("frontend-server-hollow...")
	task(f'docker build -t  "koo5/frontend-hlw{port_postfix}"    -f "frontend_server/Dockerfile_hollow" . ')


	for thread in threads:
		thread.join()
	print("ok...")


	if mode == "full":
		print()
		print("internal-workers...")
		task(f'docker build -t  "koo5/workers{port_postfix}"   -f "internal_workers/Dockerfile" . ')

	if mode == "full":
		print()
		print("internal-services...")
		task(f'docker build -t  "koo5/services{port_postfix}"  -f "internal_services/Dockerfile" . ')

	if mode == "full":
		print()
		print("frontend-server...")
		task(f'docker build -t  "koo5/frontend{port_postfix}"    -f "frontend_server/Dockerfile" . ')


	for thread in threads:
		thread.join()
	print("ok!")



if __name__ == '__main__':
    run()


