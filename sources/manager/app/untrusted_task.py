import queue
import uuid

import requests

from remoulade.middleware import CurrentMessage


fly = False


events = queue.Queue()


class Task:
	def __init__(self, task_id, proc, msg, worker_options):
		self.size = None
		self.task_id = task_id
		self.proc = proc
		self.msg = msg
		self.worker_options = worker_options
		self.results = queue.Queue()



def do_untrusted_task(task, task_id=None, input_directories=[], output_directories=[]):
	"""called from actors. The only place where Task is constructed"""
	
	if task_id is None:
		# this is gonna work as long as we dont call multiple tasks from one actor invocation. Maybe just use uuid?
		#task_id = CurrentMessage.get_current_message().message_id
		task_id = uuid.uuid4().hex
		
	task = Task(task_id=task_id, **task)

	try:
		if fly:
			fly_machine = requests.post('https://api.fly.io/v6/apps/robust/instances', json={})
			# todo copy request files to fly machine
			fly_machine.raise_for_status()

		events.push(dict(type='add_task', task=task))
		return task.results.pop()

	finally:
	
		# need to figure out a script that can tell that a fly container is not in use. This can happen if manager crashes here.
		
		if fly:
			# todo copy result files from fly machine
			fly_machine.delete()

