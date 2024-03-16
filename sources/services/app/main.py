import os, sys, logging, re
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../../common/libs/')))
from div7a import div7a
from fastapi import FastAPI


log = logging.getLogger(__name__)

app = FastAPI()



@app.get("/")
def index():
	return "ok"

@app.get("/health")
def index():
	return "ok"



@app.post("/div7a2")
def post_div7a2(request: dict):
	""" OpenAI -> frontend -> this """
	return div7a.post_div7a2(request)
