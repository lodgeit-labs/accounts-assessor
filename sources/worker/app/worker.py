import base64
import urllib
import uuid
from pathlib import Path

import urllib3.exceptions

from app import call_prolog


import logging, threading, subprocess, os, requests, sys, time

from app.host import get_unused_cpu_cores

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/misc')))
from fs_utils import file_to_json, json_to_file

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
#log.addHandler(logging.StreamHandler())
log.info('worker.py start')
log.debug('debug worker.py')


from dotdict import Dotdict


session = requests.Session()
#session.headers.update({'Authorization': 'Bearer ' + os.environ['MANAGER_TOKEN']})
#session.headers.update({'Authorization': 'Basic ' + os.environ['WORKER_AUTH']})
#print(os.environ)
aaaa = os.environ.get('WORKER_AUTH',':').split(':')
session.auth = aaaa[0], aaaa[1]
# there might be proxy variables in the environment, but we don't want to use them when talking to the manager 
session.trust_env = False
#session.timeout = (100,1000)
#session.retry = 30
connection_error_sleep_secs = 1
unused_cpu_cores = 1



def unused_cpu_cores_loop():
	global unused_cpu_cores
	while True:
		unused_cpu_cores = get_unused_cpu_cores()
		time.sleep(30)



host = os.uname().nodename
host2 = subprocess.check_output(['hostname'], text=True).strip()
if host != host2:
	log.warn(f'hostnames differ: {host=} {host2=}')
worker_id = host + '-' + str(os.getpid()) + '-' + uuid.uuid4().hex
api_url = os.environ['MANAGER_URL'] + f'/worker/' + urllib.parse.quote(worker_id, safe='') + '/'
shutdown_event = threading.Event()



def work_loop():

	# vvv thread-unsafe, but workers are spawned as separate processess, so it's fine
	global connection_error_sleep_secs

	try:		
		log.info(f'{worker_id} start work_loop')
	
		task_result = None
		cycles = 0
		while not shutdown_event.is_set():
			
			try:
				cycles += 1

				worker_info = dict(
					procs=['call_prolog', 'arelle'],
					#host_cores=os.cpu_count(),
					host_cores=unused_cpu_cores,
					host=host
				)

				log.debug(f'{worker_id} go get message, {task_result=}, {cycles=}')
			
				r = session.post(
						api_url + 'messages', 
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
					threading.Thread(target=heartbeat_loop, args=(stop_heartbeat, worker_id, task.id), name='heartbeat_loop', daemon=True).start()
					try:
						task_result = do_task(task)
					finally:
						stop_heartbeat.set()
	
			except requests.exceptions.ReadTimeout:
				# this is the normal case, happens when we get no task for a while. But note that this also catches exceptions from do_task.
				log.info('worker %s work_loop: read timeout', worker_id)
			except (requests.exceptions.HTTPError, urllib3.exceptions.MaxRetryError, urllib3.exceptions.ConnectionError, requests.exceptions.ConnectionError, urllib3.exceptions.NewConnectionError, urllib3.exceptions.ProtocolError) as e:
				# manager server is down, or somesuch
				log.info('worker %s work_loop: %s', worker_id, e)
				time.sleep(connection_error_sleep_secs)
				connection_error_sleep_secs = min(30, connection_error_sleep_secs * 1.2)
			except Exception as e:
				""" this shouldn't happen, might as well let it crash, but whatever. But it's actually how we catch exceptions from do_task currently, not sure how that should be handled correctly, we should probably regard that as an exceptional case, retriable, as opposed to known exceptions that an actual task might convert into a failure result.
				iow, whatever we failed that we catch here (or should catch around to_task, manager is gonna give the task to us again right away. Gonna happen a few times until it raises worker_died?
				"""
				log.exception('worker %s get exception %s', worker_id, e)
				time.sleep(15)
			# except e:
			# 	log.exception('worker %s get exception', worker_id)
			# 	time.sleep(5)
	
	finally:
		log.info(f'{worker_id} end.')


def do_task(task):
	remote = False

	global task_mem_file = 

	for input_file in task.input_files:
		log.debug('do_task: input_file %s', input_file)
#		if Path(input_file).exists():
#			log.debug('do_task: input_file %s exists', input_file)
#		else:
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
			
	log.info('task done: %s', task.id)
	
	return dict(task_id=task.id, result=result[0])



def upload_file(output_file):
	log.info('upload_file %s', output_file)
	json=file_to_json(output_file)
	r = session.post(api_url + 'put_file', json=json)
	r.raise_for_status()



def download_file(input_file):
	log.info('download_file %s', input_file)
	with session.post(api_url + 'get_file', json=dict(path=input_file)) as r:
		r.raise_for_status()
		r = r.json()
		os.makedirs(os.path.dirname(input_file), exist_ok=True)
		json_to_file(r, input_file)



def heartbeat_loop(stop_heartbeat, worker_id, task_id):
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


def manager_post(path, json):
	r = session.post(
			api_url + path, 
			json=json
	)
	r.raise_for_status()
	return r.json()
	