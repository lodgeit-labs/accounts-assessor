import queue, threading, time, requests
from untrusted_task import *


class Worker:
	def __init__(self, id):
		self.id = id
		self.sizes = [None]
		self.last_seen = last_seen
		self.task = None
		self.last_reported_task_ts = None
		self.last_reported_task = None
		
		

workers = {}
workers_lock = threading.Lock()
pending_tasks = []



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

		if e['type'] == 'add_task':
			sort_workers()
			task = e['task']
			try_assign_any_worker_to_task(task)	
	
		if e['type'] == 'task_result':
			if e['worker'].task:
				if e['task_result']['uuid'] == e['worker'].task.uuid:
					e['worker'].task.results.push(e['result'])
				e['worker'].task = None
				find_new_task_for_worker(e['worker'])

		workers_lock.release()


def find_new_task_for_worker(worker):
	for task in pending_tasks:
		if try_assign_worker_to_task(worker, task):
			break
			
def match_worker_to_task(worker, task):
	return task.org == worker.org and task.size in worker.sizes

def try_assign_any_worker_to_task(task):
	for worker in workers:
		if try_assign_worker_to_task(worker, task):
			return

def try_assign_worker_to_task(worker, task):
	if match_worker_to_task(worker, task):
		assign_worker_to_task(worker, task)
		return True

def assign_worker_to_task(worker, task):
	worker.task = task
	pending_tasks.remove(task)
	







