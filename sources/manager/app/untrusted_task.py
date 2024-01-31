import logging, sys

import queue
import uuid

import requests

from remoulade.middleware import CurrentMessage



log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.debug("hello from untrusted_task.py")



fly = False
separate_storage = False


events = queue.Queue()


def put_event(e):
	log.debug('put_event %s', e)
	events.put(e)

class Task:
	def __init__(self, proc, args, worker_options, input_directories=[], output_directories=[]):
		self.size = None
		
		self.id = CurrentMessage.get_current_message().message_id + '_' + uuid.uuid4().hex
		self.proc = proc
		self.args = args
		self.worker_options = worker_options
		
		self.results = queue.Queue()
		
		log.debug('task %s created', self)
		
	def __str__(self):
		return f'Task({self.id}, proc:{self.proc}, args:{self.args}, worker_options:{self.worker_options})'

	def __repr__(self):
		return f'Task({self.id}, proc:{self.proc}, args:{self.args}, worker_options:{self.worker_options})'


def copy_request_files_to_worker_container():
	pass


def copy_result_files_from_worker_container():
	pass


def do_untrusted_task(task: Task):
	"""called from actors."""

	try:
		if fly:
			fly_machine = requests.post('https://api.fly.io/v6/apps/robust/instances', json={})
			fly_machine.raise_for_status()

		if separate_storage:
			copy_request_files_to_worker_container()

		put_event(dict(type='add_task', task=task))
		log.debug('actor block on task.results.get()..')
		result = task.results.get()
		log.debug('actor got result')
	finally:
		log.debug('do_untrusted_task: finally')
		# need to figure out a script that can tell that a fly container is not in use. This can happen if manager crashes here.
		
		if separate_storage:
			copy_result_files_from_worker_container()		
		
		if fly:
			fly_machine.delete()
			
	return result
