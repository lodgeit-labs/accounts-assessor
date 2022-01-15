#!/usr/bin/env python3.9


try:
	import click
except:
	print('please install:\npython3.9 -m pip install --user -U click')
	exit(1)

import os,subprocess,time,shlex,logging,sys



import threading


class ExcThread(threading.Thread):

	def run(self):
		self.exc = None
		try:
			super().run()
		except:
			self.exc = sys.exc_info()

	def join(self):
		threading.Thread.join(self)
		if self.exc:
			if self.task:
				task = ' (' + str(self.task) + ')'
			else:
				task = ''
			msg = f"Thread '{self.getName()}'{task} threw an exception: {self.exc[1]}"
			new_exc = Exception(msg)
			raise new_exc.with_traceback(self.exc[2])



l = logging.getLogger()


l.setLevel(logging.DEBUG)
l.addHandler(logging.StreamHandler())


sq = shlex.quote
ss = shlex.split



def co(cmd):
	return subprocess.check_output(cmd, text=True, universal_newlines=True)
def cc(cmd):
	return subprocess.check_call(cmd, text=True, universal_newlines=True, bufsize=1)

def ccss(cmd):
	return cc(ss(cmd))


threads = []


def task(cmd):
	thread = ExcThread(target = ccss, args = ('stdbuf -oL -eL ' + cmd,))
	thread.task = cmd
	threads.append(thread)
	thread.start()
	if not _parallel:
		thread.join()
	return thread


def realpath(x):
	return co(['realpath', x])[:-1]


def chdir(x):
	print(f'cd {x}')
	os.chdir(x)


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

	# print()
	# print("flower...")
	# task(f'docker build -t  "koo5/flower{port_postfix}"             -f "../docker_scripts/flower/Dockerfile" . ')
	#

	chdir('../docker_scripts/')

	print()
	print("apache...")
	chdir('apache')
	task(f'docker build -t  "koo5/apache{port_postfix}"             -f "Dockerfile" . ')
	chdir('..')

	print()
	print("agraph...")
	chdir('agraph')
	task(f'docker build -t  "koo5/agraph{port_postfix}"             -f "Dockerfile" . ')
	chdir('..')

	print()
	print("super-bowl...")
	chdir('../sources/super-bowl/')
	task(f'docker build -t  "koo5/super-bowl"             -f "container/Dockerfile" . ')
	chdir('../../docker_scripts/')

	print()
	print("remoulade-api...")
	chdir('../sources/')
	task(f'docker build -t  "koo5/remoulade-api-hlw{port_postfix}"             -f "remoulade_api/Dockerfile" . ')
	chdir('../docker_scripts/')



	print()
	print("ubuntu...")
	chdir('ubuntu')
	task(f'docker build -t  "koo5/ubuntu"             -f "Dockerfile" . ').join()
	chdir('..')


	chdir('../sources/')

	# print()
	# print("remoulade-api...")
	# task(f'docker build -t  "koo5/remoulade-api{port_postfix}"             -f "remoulade_api/Dockerfile" . ')
	# chdir('..')

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


