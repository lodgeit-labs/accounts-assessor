import queue, threading, time, requests
from untrusted_job import *


class Worker:
	def __init__(self, id):
		self.id = id
		self.sizes = [None]
		self.last_seen = last_seen
		self.job = None
		self.last_reported_job_ts = None
		self.last_reported_job = None
		
		

workers = {}
workers_lock = threading.Lock()
pending_jobs = []



def get_worker(id, last_seen=None):
	""" runs in FastAPI thread. Only place where Worker is constructed """
	workers_lock.acquire()
	worker = workers.get(id)
	if worker is None:
		worker = Worker(id)
		workers[id] = worker
	if last_seen:
		worker.last_seen = last_seen
	workers_lock.release()
	return worker




def sort_workers():
	workers.sort(key=lambda w: w.last_seen, reverse=True)


def synchronization_thread():
	while True:
		e = events.pop()
		workers_lock.acquire()

		if e['type'] == 'add_job':
			sort_workers()
			job = e['job']
			try_assign_any_worker_to_job(job)	
	
		if e['type'] == 'job_result':
			if e['worker'].job:
				if e['job_result']['uuid'] == e['worker'].job.uuid:
					e['worker'].job.results.push(e['result'])
				e['worker'].job = None
				find_new_job_for_worker(e['worker'])

		workers_lock.release()


def find_new_job_for_worker(worker):
	for job in pending_jobs:
		if try_assign_worker_to_job(worker, job):
			break
			
def match_worker_to_job(worker, job):
	return job.org == worker.org and job.size in worker.sizes

def try_assign_any_worker_to_job(job):
	for worker in workers:
		if try_assign_worker_to_job(worker, job):
			return

def try_assign_worker_to_job(worker, job):
	if match_worker_to_job(worker, job):
		assign_worker_to_job(worker, job)
		return True

def assign_worker_to_job(worker, job):
	worker.job = job
	pending_jobs.remove(job)
	







