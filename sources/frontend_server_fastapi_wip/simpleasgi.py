from typing import Optional
from fastapi import FastAPI
import dotenv
import os
from glob import glob



docker_secrets = {}
for var in glob('/run/secrets/*'):
    k=var.split('/')[-1]
    v=open(var).read().rstrip('\n')
    docker_secrets[k] = v


#load_dotenv



def secret(key):
	try:
		return open('/run/secrets/'+key).read().rstrip('\n')
	except:
		return os.environ[key]
		



app = FastAPI()


@app.get("/")
async def read_root():
	return {"Hello": "World"}


@app.get("/items/{item_id}")
async def read_item(item_id: int, q: Optional[str] = None):
	return {"item_id": item_id, "q": q}






"""
When you declare a path operation function with normal def instead of async def, it is run in an external threadpool that is then awaited, instead of being called directly (as it would block the server).

If you are coming from another async framework that does not work in the way described above and you are used to define trivial compute-only path operation functions with plain def for a tiny performance gain (about 100 nanoseconds), please note that in FastAPI the effect would be quite opposite. In these cases, it's better to use async def unless your path operation functions use code that performs blocking I/O.
- https://fastapi.tiangolo.com/async/
"""

# https://12factor.net/
