#!/usr/bin/env python3.8

from celery import Celery
app = Celery(include=['internal_workers', 'call_prolog'])
	
import celeryconfig
app.config_from_object(celeryconfig)

if __name__ == '__main__':
    app.start()