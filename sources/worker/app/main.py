"""

the worker consists of two parts:
	* work_loop
	* helper api
the debuggability here might suffer from the fact that the whole work is done in a background thread. But it should be easy to run work_loop in a separate process, there is no shared state, nothing, it's just that it seems convenient that the whole service is a single process.



helper api:
	called from swipl. frontend -> rabbitmq -> proxy -> work_loop -> swipl -> helper api
	called from frontend. frontend -> helper api



parallelization:
	there can only be one http server listening per a container
		a container is:
			 a fly machine
			 a docker swarm container
			 a docker stack container in non-host network mode
	each container is therefore one worker.
	in development, it's most convenient to run stack in host mode, so, with only one worker, but we still want to parallelize.
	in production, it may also make sense to amortize the overhead of container isolation on multiple parallel jobs.
	
	therefore:
	
	we parallelize the worker, but there are three separate concerns:
		
		unicorn worker processes
			worker_processes
			> https://fastapi.tiangolo.com/deployment/server-workers/
					
			affects:
				helper api
					helper api is moreover parallelized by fastapi thread pool and asyncio
		 				> FastAPI uses a threadpool of 40 threads internally to handle requests using non-async endpoints. 
						-> the helper api has to be thread safe
				
				work_loop
					one loop is started per worker process
						* runs swipl synchronously
						* runs arelle synchronously
		
	previously, we would simply spawn multiple "workers" containers, and each would run a single actor process, subsequently single swipl process.

	

"""



import asyncio

from fastapi import Body, FastAPI
from fastapi.responses import JSONResponse
from pydantic import Field
from pydantic import BaseModel
import logging, traceback
import os, sys, logging, re, shlex, subprocess, json, threading
from pydantic.fields import Annotated
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/misc')))
import download

# this will run in background thread
from app import worker

# these are helper api
from app import account_hierarchy
from app import xml_xsd

# this is both a helper api and a task "proc"
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/')))
from div7a import div7a


logging.basicConfig()
log = logging.getLogger(__name__)
log.setLevel(logging.INFO)
#log.addHandler(logging.StreamHandler(sys.stderr))



app = FastAPI(
	title="Robust worker private api"
)



@app.on_event("shutdown")
async def shutdown():
	worker.shutdown_event.set()



worker_thread = None
async def start_worker_if_not_running():
	global worker_thread
	
	# there is no good way to make fastapi call a function after it is initialized
	await asyncio.sleep(2)
	
	# the check here might be unnecessary depending on how exactly we end up spawning the worker thread.
	if worker_thread is None:
		worker_thread = threading.Thread(target=worker.work_loop, name='work_loop', daemon=True)
		worker_thread.start()

asyncio.create_task(start_worker_if_not_running())



@app.get("/")
def get():
	return "ok"


@app.get("/health")
def get():
	return "ok"



# helper functions that prolog can call

@app.post("/arelle_extract")
def post_arelle_extract(taxonomy_locator: str):
	return account_hierarchy.ArelleController().run(taxonomy_locator)


@app.post('/xml_xsd_validator')
def xml_xsd_validator(
	xml: Annotated[str, Body(embed=True)],
	xsd: Annotated[str, Body(embed=True)]
):
	schema = xml_xsd.get_schema(xsd)
	response = {}
	try:
		schema.validate(xml)
		response['result'] = 'ok'
	except Exception as e:
		response['error_message'] = str(e)
		response['error_type'] = str(type(e))
		response['result'] = 'error'
	return JSONResponse(response)




class ShellRequest(BaseModel):
	cmd: list[str]

@app.post("/shell")
def shell(shell_request: ShellRequest):
	cmd = [shlex.quote(x) for x in shell_request.cmd]
	print(cmd)
	#p = subprocess.Popen(cmd, universal_newlines=True)  # text=True)
	p=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True)#text=True)
	(stdout,stderr) = p.communicate()
	if p.returncode == 0:
		status = 'ok'
	else:
		status = 'error'
	return JSONResponse({'status':status,'stdout':stdout,'stderr':stderr})



@app.post("/div7a")
def post_div7a(loan_summary_request: dict):
	""" excel xml -> frontend -> proxy -> worker -> prolog -> this """
	log.info(json.dumps(loan_summary_request))
	try:
		result = dict(result=div7a.div7a_from_json(loan_summary_request['data'], loan_summary_request['tmp_dir_path']))
	except div7a.MyException as e:
		result = dict(error=str(e))
	# except Exception as e:
	# 	traceback_message = traceback.format_exc()
	# 	result = dict(error=traceback_message)
	log.info(result)
	return result


app.post("/get_file_from_url_into_dir")(download.get_file_from_url_into_dir)


@app.get('/exchange_rates/{date}')
def get_exchange_rates(date: str):
	return worker.manager_post('exchange_rates', dict(date=date))