import json
import logging
from datetime import datetime

from pandas.io.formats.style import Styler
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
	with open('test.html', 'w') as ooo:
		print("""<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
  </head>
  <body>
    <main>
""",file=ooo)
		div7a_from_json2(ooo, j)
		print("""
    </main>
  </body>
</html>
""",file=ooo)


def div7a_from_json2(ooo,j):

	ciy = int(j['computation_income_year'])
	term = int(j['term'])
	principal = float(j['principal_amount'])
	ob = float(j['opening_balance'])
	creation_income_year = int(j['creation_income_year'])
	
	if principal == -1:
		if ob == -1:
			raise Exception('must specify either principal or opening balance')
	
	if principal == -1:
		principal = None

	loan_start_record = loan_start(date(creation_income_year, 6, 30), dict(principal=principal, term=term, calculation_income_year = ciy))
	
	records = SortedList([loan_start_record])
	
	records.add(calculation_start(date(ciy-1, 7, 1)))
	records.add(calculation_end(date(ciy, 6, 30)))
	records.add(loan_term_end(date(creation_income_year + term, 6, 30)))
	

	# opening balance, as specified by user, is always understood to be the opening balance of the computation income year	
	
	if ob == -1:
		pass
	else:
		records.add(opening_balance(date(ciy-1, 6, 30), dict(amount=ob)))
		
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
	records = div7a(ooo, records)

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

	if ooo:
		print(f'<h3>response</h3>', file=ooo)
		print(f'<big><pre><code>', file=ooo)
		json.dump(response, ooo, indent=True)
		print(f'</code></pre></big>', file=ooo)

	return response

def div7a(ooo, records):

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
	t2 = SortedList([r.copy() for r in t1]) # a sliced SortedList is a list, duh.
	f(t2)
	tables.append(t2)

	for r in t2:
		if r.year is None:
			r.year = r.income_year - get_loan_start_record(t2).income_year
		if r.remaining_term is None:
			rt = get_remaining_term(t2, r)
			if rt <= get_loan_start_record(t2).info['term']:
				r.remaining_term = rt
			else:
				r.remaining_term = ''
	
	if ooo:
		if in_notebook():
			from IPython.display import display, HTML
			print(f.__name__)
	
		print(f'<h3>{f.__name__}</h3>', file=ooo)
	
		dicts1 = records_to_dicts(t1)
		dicts2 = records_to_dicts(t2)
			
		df2 = pd.DataFrame(dicts2)

		if in_notebook():
			display(HTML(df2.to_html(index=False, max_rows=1000)))
	
		sss = Styler(df2)
		sss.set_table_styles([
			dict(selector='.new', props=[
				('background-color', ''),
				('font-weight', 'bold'),
				('border', 'inset'),
			]),
			dict(selector='.old', props=[('background-color', 'rgb(55, 99, 71)')]),
			dict(selector='', props=[('white-space', 'nowrap')]),
		], overwrite=False)
		sss.set_td_classes(pd.DataFrame(diff_colors(dicts1, dicts2)))
		print(sss.to_html(), file=ooo)


def diff_colors(dicts1, dicts2):
	
	rows = []
	t1_idx = 0
	for t2_idx, record2 in enumerate(dicts2):
		record2 = dicts2[t2_idx]
		all_new = dict([(k, ' new') for k, v in record2.items()])
		all_old = dict([(k, ' old') for k, v in record2.items()])


		if len(dicts1) <= t1_idx:
			rows.append(all_new)
			continue
			
		record1 = dicts1[t1_idx]
		

		# it's the same record
		if record1 == record2:
			rows.append(all_old)
			t1_idx += 1
			continue

		# it's the same record, but it's been modified
		elif record1['uuid'] == record2['uuid']:
			cells = {}
			for k, v2 in record2.items():
				if k not in record1 or v2 != record1[k]:
					cells[k] = ' new'
				else:
					cells[k] = ' old'
			rows.append(cells)
			t1_idx += 1
			continue

		# it's a new record
		else:
			rows.append(all_new)
			continue
			
	return rows

def records_to_dicts(records):
	dicts = []
	for r in records:
		info = dict(term='', note='', rate='', amount='', days='', sorting='', interest_accrued='', total_repaid='', total_repaid_for_myr_calc='', counts_towards_initial_balance='', myr_required='', shortfall='', excess='', principal='', calculation_income_year='')
		info.update(r.info)
		d = dict(
			uuid=r.uuid,
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
		del d['calculation_income_year'] # this could be inferred from calculation_start record now, and is a constant that doesnt participate in the event sequence in any way

		dicts.append(d)
	return dicts



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