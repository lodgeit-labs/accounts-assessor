#!/usr/bin/env python3


import os,subprocess,time,shlex,logging,sys,threading,tempfile,fire



logging.basicConfig(level=logging.DEBUG)
ll = logging.getLogger(__name__)



die = threading.Event()
failed = threading.Event()
flag = '../generated_stack_files/build_done.flag'



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
		ll.info(cmd)
		subprocess.check_call(cmd)
		ll.info('develop.sh finished.')
	except:
		ll.info('failure.')
		die.set()
		t.join()
		sys.exit(1)

	ll.info('wait for healtcheck thread to finish')
	t.join()
	ll.info(f'failed.is_set(): {failed.is_set()}')
	sys.exit(0 if not failed.is_set() else 1)



def health_check(public_url):

	while not die.is_set():
		try:
			open(flag)
			ll.info('build done')
			break
		except OSError:
			ll.info('waiting for build to finish')
			time.sleep(10)

	if die.is_set():
		ll.info(f'die.is_set(): {die.is_set()}')
		return

	ll.info('build done...')
	time.sleep(10)

	try:
		ll.info('health_check...')
		subprocess.check_call(shlex.split(f"""curl  --trace-time --retry-connrefused  --retry-delay 10 --retry 30 -L -S --fail --max-time 320 --header 'Content-Type: application/json' --data '---' {public_url}/health_check"""))
		ll.info('healthcheck ok')
		
	except Exception as e:
		ll.info(e)
		ll.info('healthcheck failed')
		failed.set()



if __name__ == "__main__":
	fire.Fire(run)
