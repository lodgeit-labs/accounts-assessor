import logging
from datetime import datetime

from sortedcontainers import SortedList
import pandas as pd
from .div7a_steps import *
from .div7a_checks import *


log = logging.getLogger(__name__)


pd.set_option('display.max_rows', None)
#pd.set_option('display.height', 1000)
#pd.options.display.max_rows = 1000
#https://github.com/quantopian/qgrid
#https://discourse.jupyter.org/t/interactive-exploration-without-sacrificing-reproducibility/11522/3
#https://discourse.jupyter.org/t/official-release-jupyterlab-tabular-data-editor-extension/5814



def div7a_from_json(j):
	ciy = int(j['computation_income_year'])
	
	principal = float(j['principal_amount'])
	ob = float(j['opening_balance'])
	
	if principal == -1:
		if ob == -1:
			raise Exception('must specify either principal or opening balance')
	
	if principal == -1:
		principal = None

	loan_start_record = loan_start(date(int(j['creation_income_year']), 6, 30), principal, int(j['term']))
	loan_start_record.info['calculation_income_year'] = ciy
	
	records = SortedList([loan_start_record])
	
	records.add(calculation_start(date(ciy-1, 7, 1)))
	records.add(calculation_end(date(ciy, 6, 30)))

	# opening balance, as specified by user, is always understood to be the opening balance of the computation income year	
	
	if ob == -1:
		pass
	else:
		records.add(opening_balance(date(ciy-1, 6, 30), ob))
		
	for r in j['repayments']:
		d = datetime.strptime(r['date'], '%Y-%m-%d').date()
		records.add(repayment(d, {'amount':float(r['value'])}))

	ld = j['lodgement_date']
	if ld == -1:
		pass
	else:
		lodgement_date = datetime.strptime(ld, '%Y-%m-%d').date()
		records.add(lodgement(lodgement_date))


	if not in_notebook():
		log.warn(records)
	records = div7a(records)

	myr_info = get_myr_check_of_income_year(records, ciy).info
	
	response = dict(
		income_year  =ciy,
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
	with open('test.html', 'w') as ooo:
	
		# we begin with loan_start, optional opening_balance, possible lodgement day, and then repayments.
		tables = [SortedList(records)]
		step(ooo, tables, input)
		# insert opening_balance record if it's not there
		step(ooo, tables, ensure_opening_balance_exists)
		# we insert accrual points for each income year, and for each repayment.
		step(ooo, tables, insert_interest_accrual_records)
		# we calculate the number of days of each accrual period
		step(ooo, tables, with_interest_accrual_days)
		# we propagate balance from start or from opening balance, adjusting for repayments
		step(ooo, tables, with_balance_and_accrual)
		# first year repayments either fall before or after lodgement day, affecting minimum yearly repayment calculation
		step(ooo, tables, annotate_repayments_with_myr_relevance)
		# insert minimum yearly repayment check records
		step(ooo, tables, with_myr_checks)
		# was minimum yearly repayment met?
		step(ooo, tables, evaluate_myr_checks)
		# one final check
		check_invariants(tables[-1])
		
		return tables[-1]



def step(ooo, tables, f):
	t1 = tables[-1]
	
	check_invariants(t1)
	
	t2 = SortedList(t1[:]) # a sliced SortedList is a list, duh.
	
	f(t2)
	
	tables.append(t2)

	for r in t2:
		if r.year is None:
			r.year = r.income_year - get_loan_start_record(t2).income_year
		if r.remaining_term is None:
			r.remaining_term = get_remaining_term(t2, r)
	
	if in_notebook():
		from IPython.display import display, HTML
		print(f.__name__)
		print(f'<h3>{f.__name__}</h3>', file=ooo)

		def color_cells(s):
			# if pd.notna(s) and s.startswith('1'):
			# else:
			return 'color:{0}; font-weight:bold'.format('red')
#			return ''

		df1 = df(t1)
		df2 = df(t2)

		compare = df1.compare(df2, keep_shape=True).drop('other', level=1, axis=1)
		compare = compare.droplevel(1, axis=1).dropna(how='all')
		
		df2.style.apply(lambda x: df2.applymap(color_cells), axis=None)

		display(HTML(df2.to_html(index=False, max_rows=1000)))
		print(df2.to_html(), file=ooo)
		


def df(records):
	dicts = []
	for r in records:
		info = dict(term='',note='',rate='',amount='',days='',sorting='',interest_accrued='',total_repaid='',total_repaid_for_myr_calc='',counts_towards_initial_balance='',myr_required='',shortfall='',excess='')
		info.update(r.info)
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