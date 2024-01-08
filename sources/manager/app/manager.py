import queue, threading, time, requests




class Job:
	def __init__(self, proc, msg, worker_options):
		self.proc = proc
		self.msg = msg
		self.worker_options = worker_options
		self.results = queue.Queue()

	def match(job, worker):
		return job.org == worker.org and job.size in worker.sizes


class Worker:
	def __init__(self, id, org, toworker, fromworker, lastseen):
		self.id = id
		self.org = org
		self.toworker = toworker
		self.fromworker = fromworker
		self.lastseen = lastseen
		self.job = None



events = queue.Queue()



workers = {}
workers_lock = threading.Lock()




pending_jobs = []



def get_worker(id, lastseen=None):
	""" runs in FastAPI thread. Only place where Worker is constructed """
	workers_lock.acquire()
	worker = workers.get(id)
	if worker is None:
		worker = Worker(
			id = id,
			org = org,
			toworker = queue.Queue(),
			fromworker = queue.Queue(),
			lastseen = time.now()
		)
		workers[id] = worker
	if lastseen:
		worker.lastseen = lastseen
	workers_lock.release()
	return worker



def do_job(job):
	"""called from actors. The only place where Job is constructed"""
	job = Job(**job)
	
	fly = False
	
	try:
		if fly:
			fly_machine = requests.post('https://api.fly.io/v6/apps/robust/instances', json={})
			fly_machine.raise_for_status()

		events.push(dict(type='add_job', job=job))
		return job.results.pop()

	finally:
		if fly:
			fly_machine.delete()






def synchronization_thread():
	while True:
		e = events.pop()
		workers_lock.acquire()
	
		if e['type'] == 'job_result':
			if e['worker'].job:
				e['worker'].job.results.push(e['result'])
				e['worker'].job = None
	
		if e['type'] == 'worker_reset':
			worker = e['worker']
			if worker.job:
				worker.job.push(dict(type='failure', reason='worker reset'))
				worker.job = None			
	
		elif e['type'] == 'add_job':
			job = e['job']
			for worker in workers:
				if worker.job is None and job.match(worker):
					worker.job = job
					worker.toworker.push(job.json())
					break
			else:
				pending_jobs.append(msg.job)

		workers_lock.release()

