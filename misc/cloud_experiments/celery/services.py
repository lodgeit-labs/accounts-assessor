import time

from .celery import app

from services1 import solver

@app.task
def add(x, y):
	time.sleep(x)
	return x + y

@app.task
def mul(x, y):
	return x * y


@app.task
def xsum(numbers):
	return sum(numbers)

