from pydantic import BaseModel
from typing import Optional, Any, List, Annotated, Query
from datetime import date


example1 = {
	"loan_year": 2020,
	"full_term": 7,
	"opening_balance": 100000,
	"opening_balance_year": 2020,
	"repayments": [
		{
			"date": "2021-06-30",
			"amount": 10000
		},
		{
			"date": "2022-06-30",
			"amount": 10000
		},
		{
			"date": "2023-06-30",
			"amount": 10000
		},
		{
			"date": "2024-06-30",
			"amount": 10000
		},
		{
			"date": "2025-06-30",
			"amount": 10000
		},
		{
			"date": "2026-06-30",
			"amount": 10000
		},
		{
			"date": "2027-06-30",
			"amount": 10000
		}
	]
}


class Div7aRepayment(BaseModel):
	date: date
	amount: float

	

class Div7aRequest(BaseModel):
	loan_year: Annotated[int, Query(title="The income year in which the amalgamated loan was made")]
	full_term: Annotated[int, Query(title="The length of the loan, in years")]
	opening_balance: Annotated[float, Query(title="Opening balance of the income year given by opening_balance_year.")]
	opening_balance_year: Annotated[int, Query(title="Income year of opening balance. If opening_balance_year is the income year following the income year in which the loan was made, then opening_balance is the principal amount of the loan. If user provides principal amount, then opening_balance_year should be the year after loan_year. If opening_balance_year is not specified, it is usually the current income year. Any repayments made before opening_balance_year are ignored.")]
	repayments: list[Div7aRepayment]
	lodgement_date: Annotated[Optional[date], Query(title="Date of lodgement of the income year in which the loan was made. Required if opening_balance_year is loan_year.")]


