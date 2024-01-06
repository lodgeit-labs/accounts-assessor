workers = []
events = queue.Queue()
pending_jobs = []


def match(job, worker):
	return job.org == worker.org and job.size in worker.sizes



def get_worker(id, org):
	worker = workers.get(id)
	if worker is None:
		worker = Worker(
			id = id,
			org = org,
			toworker = fifo(),
			fromworker = fifo(),
			lastseen = time.now()
		)
		workers[id] = worker
	return worker


class Job:
	def __init__(self, proc, msg, worker_options):
		self.proc = proc
		self.msg = msg
		self.worker_options = worker_options
		self.results = queue.Queue()


def do_job(job):
	"""called from actors. The only place where Job is constructed"""
	job = Job(**job)

	try:
		if fly:
			fly_machine = requsts.post('https://api.fly.io/v6/apps/robust/instances', json={})
			fly_machine.raise_for_status()

		events.push(dict(type='add_job', job=job))
		return job.results.pop()

	finally:
		if fly:
			fly_machine.delete()



def synchronization_thread():
	while True:
		e = events.pop()
		event(e)

def event(e):
	if e.type == 'job_result':
		job.worker.job = None
		job.results.push(message)


	if msg.type == 'worker_asks_for_job':
		worker = msg.worker
		if worker.job:
			worker.fromworker.push(dict(type='failure', reason='worker reset'))
		for job in pending_jobs:
			if match(job, worker):
				worker.job = job
				worker.toworker.push(job)
				break

	elif msg.type == 'add_job':
		for worker in workers:
			if worker.job is None and match(msg.job, worker):
				worker.job = job
				worker.toworker.push(msg.job)
				break
		else:
			pending_jobs.append(msg.job)

