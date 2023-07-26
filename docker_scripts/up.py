#!/usr/bin/env python3


import os,subprocess,time,shlex,logging,sys,threading,tempfile,fire


die = threading.Event()
failed = threading.Event()
flag = '../generated_stack_files/build_done.flag'



#class Up():

def run(terminal_cmd="", parallel_build=True, public_url = "http://localhost:8877", offline=False):

	try:
		os.unlink(flag)
	except:
		pass
	t = threading.Thread(target=health_check, args=(public_url,))
	t.start()
	try:
		cmd = shlex.split('./develop.sh --stay_running false')
		if terminal_cmd != True:
		      cmd += ['--terminal_cmd', terminal_cmd]
		cmd += ['--parallel_build', str(parallel_build), '--public_url', public_url, '--offline', str(offline)]# + sys.argv[1:]
		print(cmd)
		subprocess.check_call(cmd)
		print('okk..')
	except:
		die.set()
		t.join()
		sys.exit(1)

	t.join()
	sys.exit(0 if not failed.is_set() else 1)



def health_check(public_url):

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
		subprocess.check_call(shlex.split(f"""curl  --trace-time --trace-ascii - --retry-connrefused  --retry-delay 10 --retry 10 -L -S --fail --max-time 320 --header 'Content-Type: application/json' --data '---' {public_url}/health_check"""))
		print('healthcheck ok')
		
	except Exception as e:
		print(e)
		print('healthcheck failed')
		failed.set()



#if __name__ == '__main__':
#	run()
if __name__ == "__main__":
	fire.Fire(run)
