import uuid
from pathlib import Path

from app import call_prolog


import logging, threading, subprocess, os, requests, sys, time

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.addHandler(logging.StreamHandler())
log.info('worker.py start')


from dotdict import Dotdict


session = requests.Session()
session.trust_env = False
#session.timeout = (100,1000)
#session.retry = 30
connection_error_sleep_secs = 1


def work_loop():

	# thread-unsafe fun
	global connection_error_sleep_secs

	try:

		worker_id = subprocess.check_output(['hostname'], text=True).strip() + '-' + str(os.getpid()) + '_' + uuid.uuid4().hex
		worker_info = dict(procs=['call_prolog', 'arelle'])
		
		log.info(f'{worker_id} start work_loop')
	
		task_result = None
		cycles = 0
		while True:
		
			try:
				cycles += 1
				log.debug(f'{worker_id} go get message, {task_result=}, {cycles=}')
			
				r = session.post(
						os.environ['MANAGER_URL'] + f'/worker/{worker_id}/messages', 
						json=dict(
							task_result=task_result,
							worker_info=worker_info,
						)#, timeout=100
				)
	
				log.debug(f'{worker_id} done go get message')
				r.raise_for_status()
				msg = r.json()
				log.debug('worker %s got message %s', worker_id, msg)
	
				if msg.get('result_ack'):
					# waiting on result_ack gives the manager a chance to drop out for a bit, without losing the result
					task_result = None
				if msg.get('task'):
					task = Dotdict(msg['task'])
	
					stop_heartbeat = threading.Event()
					threading.Thread(target=heatbeat_loop, args=(stop_heartbeat, worker_id, task.id), name='heartbeat_loop', daemon=True).start()
					try:
						task_result = do_task(task)
					finally:
						stop_heartbeat.set()
	
			except requests.exceptions.ReadTimeout:
				# this is the normal case, happens when we get no task for a while
				log.debug('worker %s /messages read timeout', worker_id)
			except requests.exceptions.HTTPError as e:
				# manager server is down, or somesuch
				log.debug('worker %s /messages %s', worker_id, e)
				time.sleep(connection_error_sleep_secs)
				connection_error_sleep_secs = min(60, connection_error_sleep_secs * 2)
			except Exception as e:
				# this shouldn't happen, might as well let it crash, but whatever. But it's actually how we catch exceptions from do_task currently, not sure how that should be handled correctly, we should probably regard that as an exceptional case, retriable, as opposed to known exceptions that an actual task might convert into a failure result.
				# iow, whatever we failed that we catch here (or should catch around to_task, manager is gonna give the task to us again right away. Gonna happen a few times until it raises worker_died?
				log.info('worker %s get exception %s', worker_id, e)
				time.sleep(5)
			# except e:
			# 	log.exception('worker %s get exception', worker_id)
			# 	time.sleep(5)
	
	finally:
		log.info(f'{worker_id} end.')


def upload_file(output_file):
	with open(output_file, 'rb') as f:
		r = session.post(os.environ['MANAGER_URL'] + '/put_file', files=dict(path=output_file,content=f.read()))
		r.raise_for_status()	


def do_task(task):
	remote = False

	for input_file in task.input_files:
		if Path(input_file).exists():
			log.debug('do_task: input_file %s exists', input_file)
		else:
			remote = True
			download_file(input_file)
	
	if task.proc == 'call_prolog':
		result = call_prolog.call_prolog(task.args['msg'], task.args['worker_tmp_directory_name'], task.worker_options)
	elif task.proc == 'arelle':
		result = arelle(task.args, task.worker_options)
	else:
		log.warn('task bad, unknown proc: ' + str(task.proc))
		return None
	
	if remote:
		for output_file in result[1]:
			upload_file(output_file)
	
	return dict(task_id=task.id, result=result[0])


def download_file(input_file):
	with session.post(os.environ['MANAGER_URL'] + '/get_file', json=dict(fn=input_file)) as r:
		r.raise_for_status()
		os.makedirs(os.path.dirname(input_file), exist_ok=True)
		with open(input_file, 'wb') as f:
			for chunk in r.iter_content(chunk_size=58192): 
				f.write(chunk)


def heatbeat_loop(stop_heartbeat, worker_id, task_id):
	while True:
		time.sleep(10)
		if stop_heartbeat.is_set():
			break
		try:
			r = session.post(os.environ['MANAGER_URL'] + f'/worker/{worker_id}/heartbeat', json=dict(
				worker_id=worker_id, task_id=task_id))
			r.raise_for_status()
		except e:
			log.exception('worker %s get exception', worker_id)






