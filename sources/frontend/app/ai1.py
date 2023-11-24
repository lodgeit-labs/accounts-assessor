import logging
from datetime import datetime, date
import requests
from pydantic import BaseModel, Field
from typing import Optional, Any, List, Annotated
from fastapi import FastAPI, Request, File, UploadFile, HTTPException, Form, status, Query, Body, Depends
from fastapi.exceptions import RequestValidationError
from fastapi.responses import PlainTextResponse, JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.responses import RedirectResponse, PlainTextResponse, HTMLResponse
import os


from div7a2 import *

app = FastAPI(
	title="Robust API",
	summary="Invoke accounting calculators.",
	servers = [dict(url=os.environ['PUBLIC_URL'][:-1])],
)


@app.get("/", include_in_schema=False)
async def read_root():
	"""
	nothing to see here
	"""
	return {"Hello": "World"}


@app.get('/div7a')
async def div7a(
	request: Annotated[Div7aRequest, Query(examples=[example1])] = Depends(Div7aRequest),
):
	"""
	Calculate the Div 7A minimum yearly repayment, balance, shortfall and interest for a loan.
	"""
	
	# todo, optionally create job directory if needed. This isn't much of a blocking operation, and it's done exactly the same in /upload etc.

	logging.getLogger().info(request)

	# now, invoke services to do the actual work.
	return requests.post(os.environ['SERVICES_URL'] + '/div7a2', json=request).raise_for_status()

	
	

