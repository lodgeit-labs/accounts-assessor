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
	"""
	Calculate the Div 7A minimum yearly repayment, balance, shortfall and interest for a loan.
	"""
	loan_year: Annotated[int, Query(title="The income year in which the amalgamated loan was made")],
	full_term: Annotated[int, Query(title="The length of the loan, in years")],

	opening_balance: Annotated[float, Query(title="Opening balance.")],
	opening_balance_year: Annotated[int, Query(title="Income year of opening balance. If opening_balance_year is the income year following the income year in which the loan was made, then this is the principal amount of the loan. Any repayments made before the opening balance income year are ignored.")],

	repayments: Div7aRepayments,
	lodgement_date: Annotated[Optional[datetime.date], Query(title="Date of lodgement of the income year in which the loan was made. Required for calculating for the first year of loan.")]

):

