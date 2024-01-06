#!/usr/bin/env python3



import logging
import os, sys
import threading
import time
from collections import defaultdict

from remoulade import get_broker, Worker
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/misc')))
from tasking import remoulade

from fastapi import FastAPI, Request, File, UploadFile, HTTPException, Form, status, Query, Header


workers = defaultdict(stack)

def do_job(job):
	"""
	runs in remoulade actor thread.
	two options here:
	1) worker is trusted, it is running in compose/stack. It repeatedly connects to manager and asks for jobs. There is no need to spawn it, it is already running.
	2) worker is not trusted, it will be spawned as a fly.io machine here.
	at either case, we first wait for worker to register with Manager's FastAPI endpoint.
	"""

	org = job['options']['org']

	if fly:
		# spawn fly.io machine.
		fly_machine = requsts.post('https://api.fly.io/v6/apps/robust/instances', json={
		# If it does not come up in reasonable time, something went wrong.
		timeout=100
	else:
		# assume a worker is already running in compose/stack, and will register when it's free
		timeout=None

	try:
		worker = workers['org'].pop(timeout=timeout)
		worker['toworker'].append(job)
		while True:
			if len(worker['fromworker']) == 1:
				return worker['fromworker'].pop()
			elif len(worker['fromworker']) > 1:
				raise Exception('worker returned more than one result')
			time.sleep(10)
			if time.now() - worker['lastseen'] > 60 * 10:
				raise Exception('worker timed out')
	finally:
		if fly:
			fly_machine.delete()



# not sure how to compose this cleanly
import manager_actors
manager_actors.do_job = do_job



def start_worker2():
	"""
	this is a copy of remoulade.__main__.start_worker that works inside a thread
	"""

	logger = logging.getLogger('remoulade')

	broker = get_broker()
	broker.emit_after("process_boot")

	worker = Worker(broker, queues=['default'], worker_threads=1, prefetch_multiplier=1)
	worker.start()

	running = True
	while running:
		if worker.consumer_stopped:
			running = False
		if worker.worker_stopped:
			running = False
			logger.info("Worker thread is not running anymore, stopping Worker.")
		else:
			time.sleep(1)

	worker.stop(5 * 1000)
	broker.emit_before("process_stop")
	broker.close()



print(threading.Thread(target=start_worker2, daemon=True).start())



app = FastAPI(
	title="Robust API",
	summary="invoke accounting calculators and other endpoints",
)

@app.post("/connect")
def connect(org: str, id: str):
	"""
	worker calls this to register itself with manager.
	This form should only be allowed from trusted workers, because untrusted workers should be required to send a jwt instead of passing these parameters plaintext
	"""

	w = Worker(
			id = id,
			org = org,
			toworker = fifo(),
			fromworker = fifo(),
			lastseen = time.now()
	)

	worker_registrator_queue.push(w)



@app.post("/messages")
def messages(org: str, id: str):
	return(toworker[id].pop())


def result(org: str, id: str, result):
	fromworker[id].push(result)




























pending_jobs = []

def synchronization_thread():
	while True:
		e = events.pop()
		event(e)

def event(e):
	if e.type == 'job_result':
		e.worker.job = None
		e.worker.fromworker.push(message) # actor pops it

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




def match(job, worker):
	return job.org == worker.org and job.size in worker.sizes



workers = []
pending_jobs = []


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


@app.port("/worker_sends_message")
def worker_sends_message(org: str, id: str, message):
	worker = get_worker(id, org)
	synchronization_queue.push(dict(worker=w, message=message))

