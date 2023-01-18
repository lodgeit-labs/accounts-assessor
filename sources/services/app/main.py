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

