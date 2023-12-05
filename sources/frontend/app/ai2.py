from fastapi.encoders import jsonable_encoder

from div7a2 import *


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


app = FastAPI(
	title="Robust API",
	summary="Invoke accounting calculators.",
	servers=[dict(url=os.environ['PUBLIC_URL']+'/ai2')],
	root_path_in_servers=False,
)


@app.get("/", include_in_schema=False)
async def read_root():
	"""
	nothing to see here
	"""
	return {"Hello": "World"}


@app.post('/div7a')
async def div7a(

	loan_year: Annotated[int, Query(
		title="The income year in which the amalgamated loan was made",
		example=2020
	)],
	full_term: Annotated[int, Query(
		title="The length of the loan, in years",
		example=7
	)],
	opening_balance: Annotated[float, Query(
		title="Opening balance of the income year given by opening_balance_year.",
		example=100000
	)],
	opening_balance_year: Annotated[int, Query(
		title="Income year of opening balance. If opening_balance_year is the income year following the income year in which the loan was made, then opening_balance is the principal amount, of the loan. If user provides principal amount, then opening_balance_year should be the year after loan_year. If opening_balance_year is not specified, it is usually the current income year. Any repayments made before opening_balance_year are ignored.",
		example=2020
	)],
	lodgement_date: Annotated[Optional[date], Query(
		title="Date of lodgement of the income year in which the loan was made. Required if opening_balance_year is loan_year.",
		example="2021-06-30"
	)],
	repayments: Annotated[Div7aRepayments, Body(
		example=example1,
	)]
		
):
	"""
	Calculate the Div 7A minimum yearly repayment, balance, shortfall and interest for a loan.
	"""
	
	# todo, optionally create job directory if needed. This isn't much of a blocking operation, and it's done exactly the same in /upload etc.

	logging.getLogger().info(f'{loan_year=}, {full_term=}, {opening_balance=}, {opening_balance_year=}, {lodgement_date=}, {repayments=}')

	# now, invoke services to do the actual work.
	request = dict(
		request=dict(
			loan_year=loan_year,
			full_term=full_term,
			opening_balance=opening_balance,
			opening_balance_year=opening_balance_year,
			repayments=[x.dict() for x in repayments.repayments],
			lodgement_date=lodgement_date
		),
		tmp_dir_path='/app/server_root/tmp/'#fixme
	)
	return requests.post(os.environ['SERVICES_URL'] + '/div7a2', json=jsonable_encoder(request)).raise_for_status()

	
	

