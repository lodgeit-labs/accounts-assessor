#!/usr/bin/env python3


import os,subprocess,time,shlex,logging,sys,threading,tempfile


dead = False
flag = '../generated_stack_files/build_done.flag'


def run():

	try:
		os.unlink(flag)
	except:
		pass
	threading.Thread(target=health_check).start() # , daemon=True
	try:
		subprocess.check_call(shlex.split('./develop.sh --stay_running false --parallel_build true --public_url "http://robust10.local:8877"') + sys.argv[1:])
		print('okk..')
	except:
		dead = True
		exit(1)

def health_check():

	while not dead:
		try:
			open(flag)
			break
		except OSError:
			print('waiting for build to finish')
			time.sleep(10)

	print('build done...')
	time.sleep(10)

	try:
		print('health_check...')
		subprocess.check_call(shlex.split("""curl  --trace-time --trace - --retry-connrefused  --retry-delay 10 --retry 10 -L -S --fail --max-time 320 --header 'Content-Type: application/json' --data '---' http://localhost:7788/health_check"""))
		print('healthcheck ok')
		exit(0)
	except Exception as e:
		print(e)
		print('healthcheck failed')
		exit(1)


if __name__ == '__main__':
	run()
