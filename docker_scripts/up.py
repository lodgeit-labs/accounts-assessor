#!/usr/bin/env python3


import os,subprocess,time,shlex,logging,sys,threading,tempfile


dead = False


def run():
	flag = '../generated_stack_files/build_done.flag'
	try:
		os.unlink(flag)
	except:
		pass
	#threading.Thread(target=health_check, daemon=True).start()
	try:
		subprocess.check_call(shlex.split('./develop.sh --parallel_build true --public_url "http://robust10.local:8877"'))
		print('okk..')
	except:
		dead = True
		exit(1)

def health_check():
	while not dead:
		try:
			open(flag)
			break
		except:
			time.sleep(10)
	print('build done, running health check...')
	time.sleep(10)
	try:
		subprocess.check_call(shlex.split("""curl -L -S --fail --max-time 320 --header 'Content-Type: application/json' --data '---' http://localhost/health_check"""))
		exit(0)
	except:
		exit(1)


if __name__ == '__main__':
	run()
