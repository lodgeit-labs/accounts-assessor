#!/usr/bin/env python3.8
import os
from celery import Celery
app = Celery(include=['internal_workers', 'call_prolog'])
app.conf.task_default_queue = os.environ['CELERY_QUEUE_NAME']
	
import celeryconfig
app.config_from_object(celeryconfig)

if __name__ == '__main__':
    app.start()