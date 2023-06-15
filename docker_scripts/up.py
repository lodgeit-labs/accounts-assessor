#!/usr/bin/env python3


import os,subprocess,time,shlex,logging,sys,threading,tempfile


die = threading.Event()
failed = threading.Event()
flag = '../generated_stack_files/build_done.flag'


def run():

	try:
		os.unlink(flag)
	except:
		pass
	t = threading.Thread(target=health_check)
	t.start()
	try:
		cmd = shlex.split('./develop.sh --terminal_cmd "" --stay_running false --parallel_build true --public_url "http://robust10.local:8877"') + sys.argv[1:]
		print(cmd)
		subprocess.check_call(cmd)
		print('okk..')
	except:
		die.set()
		t.join()
		sys.exit(1)	

	t.join()
	sys.exit(0 if not failed.is_set() else 1)
			


def health_check():

	while not die.is_set():
		try:
			open(flag)
			break
		except OSError:
			print('waiting for build to finish')
			time.sleep(10)

	if die.is_set():
		return

	print('build done...')
	time.sleep(10)

	try:
		print('health_check...')
		subprocess.check_call(shlex.split("""curl  --trace-time --trace-ascii - --retry-connrefused  --retry-delay 10 --retry 10 -L -S --fail --max-time 320 --header 'Content-Type: application/json' --data '---' http://localhost:7788/health_check"""))
		print('healthcheck ok')
		
	except Exception as e:
		print(e)
		print('healthcheck failed')
		failed.set()



if __name__ == '__main__':
	run()
