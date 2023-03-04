import os, sys
import urllib.parse
import json
import datetime
import ntpath
import shutil
from typing import Optional, Any
from fastapi import FastAPI, Request, File, UploadFile
from pydantic import BaseModel

app = FastAPI()

#sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../internal_workers')))
#sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common')))


import account_hierarchy


@app.post("/arelle_extract")
def arelle_extract(taxonomy_locator: str):
	return account_hierarchy.ArelleController().run(taxonomy_locator)


@app.get("/")
def index():
	return "ok"



from pydantic import BaseModel


class ShellRequest(BaseModel):
    cmd: list[str]

@app.post("/shell")
def rpc(shell_request: ShellRequest):
	cmd = [shlex.quote(x) for x in shell_request['cmd']]
	print(cmd)
	#p = subprocess.Popen(cmd, universal_newlines=True)  # text=True)
	p=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True)#text=True)
	(stdout,stderr) = p.communicate()
	if p.returncode == 0:
		status = 'ok'
	else:
		status = 'error'
	return JsonResponse({'status':status,'stdout':stdout,'stderr':stderr})
