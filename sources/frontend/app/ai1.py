import logging
from datetime import datetime
from typing import Annotated, Optional

import requests
from fastapi import Query


class Div7aRepayment(BaseModel):
	date: datetime.date
	amount: float

class Div7aRepayments(BaseModel):
	repayments: list[Div7aRepayment]


app = FastAPI(
	title="Robust API",
	summary="Invoke accounting calculators.",
	servers = [dict(url=os.environ['PUBLIC_URL'][:-1])],
)

@app.get('/div7a')
async def div7a(
	loan_year: Annotated[int, Query(title="The income year in which the amalgamated loan was made")],
	full_term: Annotated[int, Query(title="The length of the loan, in years")],
	opening_balance: Annotated[float, Query(title="Opening balance of the income year given by opening_balance_year.")],
	opening_balance_year: Annotated[int, Query(title="Income year of opening balance. If opening_balance_year is the income year following the income year in which the loan was made, then opening_balance is the principal amount of the loan. If user provides principal amount, then opening_balance_year should be the year after loan_year. If opening_balance_year is not specified, it is usually the current income year. Any repayments made before opening_balance_year are ignored.")],
	repayments: Div7aRepayments,
	lodgement_date: Annotated[Optional[datetime.date], Query(title="Date of lodgement of the income year in which the loan was made. Required for calculating for the first year of loan.")]
):
	"""
	Calculate the Div 7A minimum yearly repayment, balance, shortfall and interest for a loan.
	"""
	
	# todo, optionally create job directory if needed. This isn't much of a blocking operation, and it's done exactly the same in /upload etc.

	# now, invoke services to do the actual work.

	logging.getLogger().info(f'/ai1/div7a: {loan_year=}, {full_term=}, {opening_balance=}, {opening_balance_year=}, {repayments=}, {lodgement_date=}')

	requests.post(os.environ['SERVICES_URL'] + '/div7a2', json={"root": "ic_ui:investment_calculator_sheets", "input_fn": str(uploaded), "output_fn": str(to_be_processed)}).raise_for_status()

	
	

