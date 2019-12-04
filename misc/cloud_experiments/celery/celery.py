#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import time

from celery import Celery

from services1 import celeryconfig

app = Celery(
	'services1', 
	include=['services1.services'])
	
app.config_from_object(celeryconfig)


if __name__ == '__main__':
    app.start()