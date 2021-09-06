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



def co(cmd):
	return subprocess.check_output(cmd, text=True, universal_newlines=True)
def cc(cmd):
	return subprocess.check_call(cmd, text=True, universal_newlines=True)
ss = shlex.split

def ccss(cmd):
	return cc(ss(cmd))


def realpath(x):
	return co(['realpath', x])[:-1]



@click.command(help="""build the docker images.""")

@click.option('-pp', '--port_postfix', 				type=str, 	default='', 
	help="last two or more digits of the services' public ports. Also identifies the particular docker stack.")

@click.option('-m', '--mode', 				type=str, 	default='full', 
	help="hollow or full images? mount host directories containing source code or copy everything into image?")

def run(port_postfix, mode):
	cc('../docker_scripts/git_info.fish')

	print()
	print("flower...")
	ccss(f'docker build -t  "koo5/flower{port_postfix}"             -f "../docker_scripts/flower/Dockerfile" . ') 
	
	print()
	print("apache...")
	ccss(f'docker build -t  "koo5/apache{port_postfix}"             -f "../docker_scripts/apache/Dockerfile" . ')

	print()
	print("agraph...")
	ccss(f'docker build -t  "koo5/agraph{port_postfix}"             -f "../docker_scripts/agraph/Dockerfile" . ')

	print()
	print("internal-workers-hollow...")
	ccss(f'docker build -t  "koo5/internal-workers-hollow{port_postfix}"   -f "internal_workers/Dockerfile_hollow" . ')

	if mode == "full":
		print()
		print("internal-workers...")
		ccss(f'docker build -t  "koo5/internal-workers{port_postfix}"   -f "internal_workers/Dockerfile" . ')

	print()
	print("internal-services-hollow...")
	ccss(f'docker build -t  "koo5/internal-services-hollow{port_postfix}"  -f "internal_services/Dockerfile_hollow" . ')

	if mode == "full":
		print()
		print("internal-services...")
		ccss(f'docker build -t  "koo5/internal-services{port_postfix}"  -f "internal_services/Dockerfile" . ')
	
	print()
	print("frontend-server-hollow...")
	ccss(f'docker build -t  "koo5/frontend-server-hollow{port_postfix}"    -f "frontend_server/Dockerfile_hollow" . ')

	if mode == "full":
		print()
		print("frontend-server...")
		ccss(f'docker build -t  "koo5/frontend-server{port_postfix}"    -f "frontend_server/Dockerfile" . ')


	print("ok")




if __name__ == '__main__':
    run()


