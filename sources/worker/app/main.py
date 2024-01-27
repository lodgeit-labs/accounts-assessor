"""

the worker consists of two parts:
	* work_loop
	* helper api



helper api:
	called from swipl. frontend -> rabbitmq -> proxy -> work_loop -> swipl -> helper api
	called from frontend. frontend -> helper api



on parallelization:
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



from fastapi import Body, FastAPI
from fastapi.responses import JSONResponse
from pydantic import Field
from pydantic import BaseModel
import logging
import os, sys, logging, re, shlex, subprocess, json
from pydantic.fields import Annotated
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/misc')))

# this will run in background thread
from app import worker
worker

# these are helper api
from app import account_hierarchy
from app import xml_xsd

# this is both a helper api and a task "proc"
from div7a import div7a


log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.addHandler(logging.StreamHandler(sys.stderr))



app = FastAPI(
	title="Robust worker private api"
)


# helper functions that prolog can call


@app.get("/")
def root():
	return "ok"


@app.get("/health")
def root():
	return "ok"


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
		result = dict(result='error', error_message=str(e))
	except Exception as e:
		traceback_message = traceback.format_exc()
		result = dict(result='error', error_message=traceback_message)
	log.info(result)
	return result


