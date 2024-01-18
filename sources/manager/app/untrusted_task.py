import queue
import uuid

import requests

from remoulade.middleware import CurrentMessage


fly = False


events = queue.Queue()


class Task:
	def __init__(self, proc, args, worker_options, input_directories=[], output_directories=[]):
		self.size = None
		
		self.task_id = CurrentMessage.get_current_message().message_id + '_' + uuid.uuid4().hex
		self.proc = proc
		self.args = args
		self.worker_options = worker_options
		
		self.results = queue.Queue()



def do_untrusted_task(task: Task):
	"""called from actors."""

	try:
		if fly:
			fly_machine = requests.post('https://api.fly.io/v6/apps/robust/instances', json={})
			# todo copy request files to fly machine
			fly_machine.raise_for_status()

		events.put(dict(type='add_task', task=task))
		return task.results.get()

	finally:
	
		# need to figure out a script that can tell that a fly container is not in use. This can happen if manager crashes here.
		
		if fly:
			# todo copy result files from fly machine
			fly_machine.delete()

