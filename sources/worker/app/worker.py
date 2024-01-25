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
			log.debug(f'{worker_id} go get message, {task_result=}')
		
			r = requests.post(os.environ['MANAGER_URL'] + f'/worker/{worker_id}/messages', json=dict(
				task_result=task_result,
				worker_info=worker_info,
			), timeout=100)
			r.raise_for_status()
			msg = r.json()
			log.debug('worker %s got message %s', worker_id, msg)

			if msg.get('result_ack'):
				task_result = None
			if msg.get('task'):
				task = Dotdict(msg['task'])
				if task.proc == 'call_prolog':
					task_result = dict(task_id=task.id, result=call_prolog.call_prolog(task.args['msg'], task.worker_options))
				elif task.proc == 'arelle':
					task_result = dict(task_id=task.id, result=arelle(task.args, task.worker_options))
				else:
					log.warn('task bad, unknown proc: ' + str(task.proc))

		except requests.exceptions.ReadTimeout:
			log.debug('worker %s /messages read timeout', worker_id)
		except requests.exceptions.HTTPError as e:
			log.debug('worker %s /messages %s', worker_id, e)
			time.sleep(5)
		except Exception as e:
			log.exception('worker %s get exception', worker_id)
			time.sleep(5)


# the debuggability here might suffer from the fact that the whole work is done in a background thread. But it should be easy to run this in a separate process, there is no shared state, nothing, it's just that it seems convenient that the whole service is a single process. But it's not a requirement.

threading.Thread(target=manager_proxy_thread, name='manager_proxy_thread', daemon=True).start()




