from app import call_prolog


import logging, threading, subprocess, os, requests


from dotdict import Dotdict


def manager_proxy_thread():

	client_id = subprocess.check_output(['hostname'], text=True).strip() + '-' + str(os.getpid())
	worker_info = dict(id=client_id, procs=[
			'call_prolog',
		  # should be handled in worker helper api
		#  'arelle',
		  # we should be able to safely route from worker fly machine to download bastion, making this unnecessary as well
		#  'download',
	])

	while True:
		r = requests.post(os.environ['MANAGER_URL'] + '/messages', json=worker_info)
		r.raise_for_status()
		msg = Dotdict(r.json())

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
				raise Exception('unknown proc: ' + msg.proc)


# the debuggability here might suffer from the fact that the whole work is done in a background thread. But it should be easy to run this in a separate process, there is no shared state, nothing, it's just that it seems convenient that the whole service is a single process. But it's not a requirement.

#threading.Thread(target=manager_proxy_thread, name='manager_proxy_thread', daemon=True).start()




