
"""
# record order / sorting:

the fact that we want to be able to have an interest accrual for year end, followed by lodgement date, or opening balance, or repayment, and another interest accrual, at the same date, shows that it's not possible to simply sort by date, then by type.

copilot idea:

 we need to sort by date, then by type, then by order of insertion. so we need to keep track of the order of insertion. we can do this by adding a field to the record class, and incrementing it each time we insert a record.
  - but this only shifts the problem revealing the issue of implicit ordering of records through the implementation details of the computations.
 - another form of this is optionally specifying something like "goes_after" and "goes_before" in some records, referencing other records. 

The obvious but a bit more complex solution is inserting records at their exact places right when they are created. Also i don't like this this is still very much implicit / "trust me" situation.

The best solution is to have a function that takes a list of records, and a new record, and returns a new list of records with the new record inserted at the right place. This function should be used everywhere where we insert records. This way, the order of records is always explicit, and we can always reason about it.  


# an interesting observation is that repayments on the last day of income year always come before the final interest accrual for the income year. 


consider this trivial example as an input to insert_interest_accrual_records:

records = [
	loan_start(date(2020, 6, 30), 10000, 5),
	opening_balance(date(2021, 6, 30), 2000),
]

an iy-end accrual has to be inserted before the opening balance.  

# visualization:
pandas dataframe with columns. There is an option to output custom html. We will need to generate html files. We can use the same html template for all of them, and just pass in the dataframes. We can also use the same css for all of them.





"""
import pandas as pd
from sortedcontainers import SortedList

from div7a_steps import *
from div7a_checks import *

pd.set_option('display.max_rows', None)
#pd.set_option('display.height', 1000)
#pd.options.display.max_rows = 1000
#https://github.com/quantopian/qgrid
#https://discourse.jupyter.org/t/interactive-exploration-without-sacrificing-reproducibility/11522/3
#https://discourse.jupyter.org/t/official-release-jupyterlab-tabular-data-editor-extension/5814




def div7a_from_json(j):

	principal = j['principal']
	if principal == -1:
		principal = None

	records = SortedList(loan_start(date(j['creation_income_year'], 6, 30), principal, j['term']))
		
	ob = j['opening_balance']
	if ob == -1:
		pass
	else:
		records.add(opening_balance(date(j['computation_income_year'], 6, 30), ob))
		
	for r in j['repayments']:
		records.add(repayment(date(r['income_year'], r['month'], r['day']), r['amount']))

	records = div7a(records)[-1]

	myr_info = get_myr_check_of_income_year(records, income_year).myr_info
	ciy = j['computation_income_year']
	response = dict(
		income_year =ciy,
		opening_balance = loan_agr_year_opening_balance(records, ciy),
		interest_rate = benchmark_rate(ciy),
		min_yearly_repayment = myr_info['myr_required'],
		total_repayment = myr_info['total_repaid_for_myr_calc'],
		repayment_shortfall = myr_info['shortfall'],
		total_interest = total_interest_accrued(records, ciy),
		total_principal = total_principal_paid(records, ciy),
		closing_balance = closing_balance(records, ciy),
	)

	return response

def div7a(records):
	"""
1)

	fiscal_year_atlim
	first_fiscal_year_atlim
	

2)
	hmm i need to introduce the "opening_balance" as an explicit record even in the case that it's not user-provided.



	Where a repayment is made before {the private company's lodgment day for the year in which the amalgamated loan is made}, the principal amount at 1 July of the first income year after the loan is made, is not the sum total of the constituent loans at 1 July. Rather, it is the sum of the constituent loans immediately before the lodgment day. For this purpose, payments made before lodgment day are taken to have been made in the year the amalgamated loan is made.



	"""
	# we begin with loan_start, optional opening_balance, possible lodgement day, and then repayments.
	tables = [SortedList(records)]
	step(tables, input)
	# insert opening_balance record if it's not there

	# we insert accrual points for each income year, and for each repayment.
	step(tables, insert_interest_accrual_records)
	# we calculate the number of days of each accrual period
	step(tables, with_interest_accrual_days)
	# we propagate balance from start or from opening balance, adjusting for repayments
	step(tables, with_balance_and_accrual)
	# first year repayments either fall before or after lodgement day, affecting minimum yearly repayment calculation
	step(tables, annotate_repayments_with_myr_relevance)
	# insert minimum yearly repayment check records
	step(tables, with_myr_checks)
	# was minimum yearly repayment met?
	step(tables, evaluate_myr_checks)
	# one final check
	check_invariants(tables[-1])
	return records


def step(tables, f):
	check_invariants(tables[-1])
	# a sliced SortedList is a list, duh. 
	t = SortedList(tables[-1][:])
	f(t)
	tables.append(t)

	for r in t:
		if r.year is None:
			r.year = r.income_year - get_loan_start_record(t).income_year
		if r.remaining_term is None:
			r.remaining_term = get_remaining_term(t, r)
	
	if in_notebook():
		from IPython.display import display, HTML
		print(f.__name__)
		display(HTML(df(tables[-1]).to_html(index=False, max_rows=1000)))


def df(records):
	dicts = []
	for r in records:
		info = dict(term='',note='',rate='',amount='',days='',sorting='',interest_accrued='',total_repaid='',total_repaid_for_myr_calc='',counts_towards_initial_balance='',myr_required='',shortfall='',excess='')
		info.update(r.myr_info)
		d = dict(
			year=r.year,
			remain=r.remaining_term,
			fiscal=r.income_year,
			date=r.date,
			type=r.__class__.__name__,
			final_balance=r.final_balance,
			**info)

		if d['final_balance'] == None:
			d['final_balance'] = ''
			
		del d['sorting']
		
		dicts.append(d)

	f = pd.DataFrame(dicts)

	return f
	
	
def in_notebook():
	"""
	https://stackoverflow.com/questions/15411967/how-can-i-check-if-code-is-executed-in-the-ipython-notebook
	"""
	try:
		from IPython import get_ipython
		if 'IPKernelApp' not in get_ipython().config:  # pragma: no cover
			return False
	except ImportError:
		return False
	except AttributeError:
		return False
	return True


def input(x):
	"""dummy step"""
	pass