from app import call_prolog


import logging, threading, subprocess, os, requests, sys, time

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.addHandler(logging.StreamHandler())
log.info('worker.py start')


from dotdict import Dotdict


def manager_proxy_thread():

	worker_id = subprocess.check_output(['hostname'], text=True).strip() + '-' + str(os.getpid())
	worker_info = dict(procs=[
			'call_prolog',
		  # should be handled in worker helper api
		#  'arelle',
		  # we should be able to safely route from worker fly machine to download bastion, making this unnecessary as well
		#  'download',
	])

	task_result = None
	
	while True:
	
		try:
			log.debug('worker %s go get message', worker_id)
		
			r = requests.post(os.environ['MANAGER_URL'] + f'/worker/{worker_id}/messages', data=dict(
				worker_id=worker_id,
				task_result=task_result,
				worker_info=worker_info,
			), timeout=10)
			r.raise_for_status()
			msg = Dotdict(r.json())
			log.debug('worker %s got message %s', worker_id, msg)
	
			if msg.type == 'job':
				if msg.proc == 'call_prolog':
					return call_prolog.call_prolog(msg.msg, msg.worker_options)
				if msg.proc == 'call_prolog_calculator':
					return call_prolog.call_prolog_calculator(msg.msg, msg.worker_options)
				elif msg.proc == 'arelle':
					return arelle(msg.msg, msg.worker_options)
	#			elif msg['proc'] == 'download':
	#				return download(msg['msg'], msg['worker_options'])
	#				safely covered by download_bastion i think
				else:
					raise Exception('message bad, unknown proc: ' + msg.proc)
		except requests.exceptions.ReadTimeout:
			log.debug('worker %s manager read timeout', worker_id)
		except Exception as e:
			log.exception('worker %s get exception', worker_id)
			time.sleep(5)


# the debuggability here might suffer from the fact that the whole work is done in a background thread. But it should be easy to run this in a separate process, there is no shared state, nothing, it's just that it seems convenient that the whole service is a single process. But it's not a requirement.

threading.Thread(target=manager_proxy_thread, name='manager_proxy_thread', daemon=True).start()




