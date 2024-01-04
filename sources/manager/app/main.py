#!/usr/bin/env python3



import logging
import os, sys
import threading
import time

from remoulade import get_broker, Worker
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/misc')))
from tasking import remoulade

from fastapi import FastAPI, Request, File, UploadFile, HTTPException, Form, status, Query, Header


from manager_actors import local_rpc, local_calculator
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

