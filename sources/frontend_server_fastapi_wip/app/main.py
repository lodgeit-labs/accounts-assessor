from typing import Optional
from fastapi import FastAPI


import os
from glob import glob


def ee(context_manager):
	return ExitStack().enter_context(context_manager)

def secret(key):
	try:
		stack = ee(open('/run/secrets/'+key))
	except FileNotFoundError:
		pass
	else:
		with stack as f:
			return f.read().rstrip('\n')


	return os.environ[key]



app = FastAPI()


@app.get("/")
async def read_root():
	return {"Hello": "World"}


@app.get("/items/{item_id}")
async def read_item(item_id: int, q: Optional[str] = None):
	return {"item_id": item_id, "q": q}






"""
FastAPI def vs async def:

When you declare a path operation function with normal def instead of async def, it is run in an external threadpool that is then awaited, instead of being called directly (as it would block the server).

If you are coming from another async framework that does not work in the way described above and you are used to define trivial compute-only path operation functions with plain def for a tiny performance gain (about 100 nanoseconds), please note that in FastAPI the effect would be quite opposite. In these cases, it's better to use async def unless your path operation functions use code that performs blocking I/O.
- https://fastapi.tiangolo.com/async/
"""

# https://12factor.net/
