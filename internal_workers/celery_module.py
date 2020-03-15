#!/usr/bin/env python3.8
import os
from celery import Celery

app = Celery(include=['internal_workers', 'call_prolog'])
	
import celeryconfig
app.config_from_object(celeryconfig)

app.conf.task_default_queue = os.environ['CELERY_QUEUE_NAME']

import json
with open('../../secrets2.json', 'r') as s:
	secrets = json.load(s)
app.conf.AGRAPH_SECRET_USER = secrets['AGRAPH_SECRET_USER']
app.conf.AGRAPH_SECRET_PASSWORD = secrets['AGRAPH_SECRET_PASSWORD']
del secrets

if __name__ == '__main__':
    app.start()