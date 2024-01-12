import queue

import requests

from remoulade.middleware import CurrentMessage

events = queue.Queue()


class Job:
	def __init__(self, job_id, proc, msg, worker_options):
		self.size = None
		self.job_id = job_id
		self.proc = proc
		self.msg = msg
		self.worker_options = worker_options
		self.results = queue.Queue()



def do_untrusted_job(job, job_id=None):
	"""called from actors. The only place where Job is constructed"""
	
	if job_id is None:
		job_id = CurrentMessage.get_current_message().message_id
	job = Job(job_id=job_id, **job)
	
	fly = False
	
	try:
		if fly:
			fly_machine = requests.post('https://api.fly.io/v6/apps/robust/instances', json={})
			fly_machine.raise_for_status()

		events.push(dict(type='add_job', job=job))
		return job.results.pop()

	finally:
	
		# need to figure out a script that can tell that a fly container is not in use. This can happen if manager crashes here.
		
		if fly:
			fly_machine.delete()

