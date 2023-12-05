import json
from json import JSONEncoder
import logging
import pathlib
from datetime import datetime, date

from pandas.io.formats.style import Styler
import pandas as pd
from .div7a_steps import *
from .div7a_checks import *


log = logging.getLogger(__name__)



class MyEncoder(JSONEncoder):
	def default(self, obj):
		if isinstance(obj, date):
			return str(obj)
		return json.JSONEncoder.default(self, obj)



pd.set_option('display.max_rows', None)
#pd.set_option('display.height', 1000)
#pd.options.display.max_rows = 1000
#https://github.com/quantopian/qgrid
#https://discourse.jupyter.org/t/interactive-exploration-without-sacrificing-reproducibility/11522/3
#https://discourse.jupyter.org/t/official-release-jupyterlab-tabular-data-editor-extension/5814



def div7a_from_json(j,tmp_dir_path='.'):
	with open(pathlib.PosixPath(tmp_dir_path) / 'test.html', 'w') as ooo:
		print("""<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
  </head>
  <body>
    <main>
""",file=ooo)
		r = div7a_from_json2(ooo, j)
		print("""
    </main>
  </body>
</html>
""",file=ooo)
	return r

def div7a_from_json2(ooo,j):

	"""
	given starting amount as:
		<loan principal> (same as opening balance at first year)
		or
		opening balance at calculation income year
		or
		<opening balance> at <income year> (not supported here)
		
	given repayments for:
		all the years - in case of principal provided
		or
		only the calculation year - in case of opening balance provided
		or
		years since opening balance of <income year> - in case of opening balance of <income year> provided 
	
	given lodgement day:
		<date> - in case of calculation of first loan year, this is implied by:
			principal provided
			opening balance at calculation income year, where calculation income year is the first year after loan creation
			<opening balance> at <income year>, where <income year> is the first year after loan creation	
	
	...	
	 
	"""

	if ooo:
		print(f'<h3>request</h3>', file=ooo)
		print(f'<big><pre><code>', file=ooo)
		json.dump(j, ooo, indent=True)
		print(f'</code></pre></big>', file=ooo)

	ciy = int(j['computation_income_year'])
	term = int(j['term'])
	principal = float(j['principal_amount'])
	ob = float(j['opening_balance'])
	creation_income_year = int(j['creation_income_year'])
	
	if principal == -1:
		if ob == -1:
			raise MyException('must specify either principal or opening balance')
	
	if principal == -1:
		principal = None

	records = []

	loan_start_record = loan_start(date(creation_income_year, 6, 30), dict(principal=principal, term=term, calculation_income_year = ciy))

	rec_add(records, loan_start_record)
	
	rec_add(records, calculation_start(date(ciy-1, 7, 1)))
	rec_add(records, calculation_end(date(ciy, 6, 30)))
	rec_add(records, loan_term_end(date(creation_income_year + term, 6, 30)))
	

	# opening balance, as specified by user, is always understood to be the opening balance of the computation income year	
	
	if ob == -1:
		pass
	else:
		if principal is not None and ciy == creation_income_year + 1:
			raise MyException(f'opening balance for income year {ciy} must be equal to principal, or one must be omitted.')
		
		rec_add(records, opening_balance(date(ciy-1, 6, 30), dict(amount=ob)))
		
	for r in j['repayments']:
		d = datetime.strptime(r['date'], '%Y-%m-%d').date()
		rec_add(records, repayment(d, {'amount':float(r['value'])}))

	ld = j['lodgement_date']
	if ld == -1:
		pass
	else:
		lodgement_date = datetime.strptime(ld, '%Y-%m-%d').date()
		rec_add(records, lodgement(lodgement_date))


	if not in_notebook():
		log.warn(records)
	records = div7a(ooo, records)

	myr_info = get_myr_check_of_income_year(records, ciy).info
	
	response = dict(
		income_year  =ciy,
		opening_balance = loan_agr_year_opening_balance(records, ciy),
		interest_rate = benchmark_rate(ciy),
		min_yearly_repayment = myr_info['myr_required'],
		total_repayment = total_repayment_in_income_year(records, ciy),
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
	tables = [list(records)]
	step(ooo, tables, input)
	# insert opening_balance record if it's not there
	step(ooo, tables, ensure_opening_balance_exists)
	# we insert accrual points for each income year, and for each repayment.
	step(ooo, tables, insert_interest_calc_records)
	# we calculate the number of days of each accrual period
	step(ooo, tables, with_interest_calc_days)
	# we propagate balance from start or from opening balance, adjusting for repayments
	step(ooo, tables, with_balance)
	# first year repayments either fall before or after lodgement day, affecting minimum yearly repayment calculation
	step(ooo, tables, annotate_repayments_with_myr_relevance)
	# insert minimum yearly repayment check records
	step(ooo, tables, with_myr_checks)
	# was minimum yearly repayment met?
	step(ooo, tables, evaluate_myr_checks, True)
	# one final check
	check_invariants(tables[-1])
	
	return tables[-1]



def step(ooo, tables, f, final=False):
	t1 = tables[-1]
	check_invariants(t1)
	t2 = [r.copy() for r in t1] 
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

		dicts1 = records_to_dicts(t1)
		dicts2 = records_to_dicts(t2)
		df2 = pd.DataFrame(dicts2)

		print(f'<h3>{f.__name__}</h3>', file=ooo)

		if in_notebook() and final:
			from IPython.display import display, HTML
			print(f.__name__)
			display(HTML(df2.to_html(index=False, max_rows=1000)))
	
		sss = Styler(df2)
		sss.set_table_styles([
			dict(selector='.new', props=[
				('background-color', ''),
				('font-weight', 'bold'),
				('border', 'inset'),
			]),
			#dict(selector='.old', props=[('background-color', 'rgb(55, 99, 71)')]),
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

		#del d['sorting']
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





def div7a2_from_json(j,tmp_dir_path='.'):
	with open(pathlib.PosixPath(tmp_dir_path) / 'test.html', 'w') as ooo:
		print("""<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
  </head>
  <body>
    <main>
""",file=ooo)
		if ooo:
			print(f'<h3>request</h3>', file=ooo)
			print(f'<big><pre><code>', file=ooo)
			json.dump(j, ooo, indent=True)
			print(f'</code></pre></big>', file=ooo)

		r = div7a2_from_json2(ooo, j)

		if ooo:
			print(f'<h3>response</h3>', file=ooo)
			print(f'<big><pre><code>', file=ooo)
			json.dump(r, ooo, indent=True, cls=MyEncoder)
			print(f'</code></pre></big>', file=ooo)

		print("""
    </main>
  </body>
</html>
""",file=ooo)
	return r


def repayments_amount_before_lodgement(records, year):
	"""
	How much was repaid before lodgement day in the year?
	"""
	return sum([r.info['amount'] for r in records if r.__class__ == repayment and r.info['counts_towards_initial_balance']])


def repayments_amount_after_lodgement(records, year):
	"""
	How much was repaid after lodgement day in the year?
	"""
	return sum([r.info['amount'] for r in records if r.__class__ == repayment and not r.info['counts_towards_initial_balance']])


#def income_year_closing_balance(records, year):
#	return records_of_income_year(records, year)[-1].final_balance


def div7a2_from_json2(ooo,j):

	full_term, principal, records = div7a2_ingest(j)

	# debug

	if not in_notebook():
		log.warn(records)

	# computation

	records = div7a(ooo, records)

	# answer
	
	overview = []

	loan_start_record = get_loan_start_record(records)
	first_year = loan_start_record.income_year
	
	overview.append(dict(
		year=first_year,
		events=[dict(
			type="loan created", 
			date=loan_start_record.date, 
			loan_principal=principal if principal is not None else "unknown",
			loan_term=loan_start_record.info['term'],
		)],
	))
	
	year = first_year + 1
	
	while year <= first_year + full_term:
		y = dict(
			year=year,
			events=[]
		)

		iyr = records_of_income_year(records, year)
		ob = iyr[-1].final_balance
		if ob is not None:
			y['opening_balance'] = ob
		
		for r in iyr:
			if r.__class__ in [lodgement, repayment]:
				if r.__class__ == lodgement:
					y['events'].append(dict(
						type='lodgement',
						date=r.date
					))
				elif r.__class__ == repayment:
					y['events'].append(dict(
						type='repayment',
						date=r.date,
						amount=r.info['amount']
					))

		if year is first_year + 1:
			y['total_repaid_before_lodgement'] = repayments_amount_before_lodgement(records, year)
			y['total_repaid_after_lodgement'] = repayments_amount_after_lodgement(records, year)

		if ob is not None:
			myr_info = get_myr_check_of_income_year(records, year).info
			
			y['opening_balance'] = loan_agr_year_opening_balance(records, year)
			y['interest_rate'] = benchmark_rate(year)
			y['minimum_yearly_repayment'] = myr_info['myr_required']
			y['total_repaid'] = total_repayment_in_income_year(records, year)
			if repayments(iyr) != []:
				if myr_info['shortfall'] > 0:
					y['repayment_shortfall'] = myr_info['shortfall']
				if myr_info['excess'] > 0:
					y['repayment_excess'] = myr_info['excess']
				y['total_principal_paid'] = total_principal_paid(records, year)
			y['total_interest_accrued'] = total_interest_accrued(records, year)
			y['closing_balance'] = closing_balance(records, year)
			#y['closing_balance'] = income_year_closing_balance(records, year)

		overview.append(y)
		
		if y.get('repayment_shortfall') not in [None, 0]:
			break

		year += 1
		
	return overview


def div7a2_ingest(j):
	records = []
	for r in j['repayments']:
		d = datetime.strptime(r['date'], '%Y-%m-%d').date()
		r = repayment(d, {'amount': float(r['amount'])})
		if r.income_year not in benchmark_rates:
			raise MyException(f'Cannot calculate with repayments in income year {r.income_year}')
		rec_add(records, r)
	loan_year = int(j['loan_year'])
	full_term = int(j['full_term'])
	ob = float(j['opening_balance'])
	oby = int(j['opening_balance_year'])
	last_calculation_income_year = div7a2_calculation_income_year(loan_year, full_term, repayments(records))
	if oby < loan_year:
		raise MyException('opening balance year must be after loan year')
	if oby == loan_year:
		principal = ob
	else:
		principal = None
		rec_add(records, opening_balance(date(oby, 7, 1), dict(amount=ob)))
	rec_add(records, loan_start(date(loan_year, 6, 30), dict(principal=principal, term=full_term, calculation_income_year=last_calculation_income_year)))
	# calculation_start is wrong..
	rec_add(records, calculation_start(date(oby, 7, 1)))
	rec_add(records, calculation_end(date(last_calculation_income_year, 6, 30)))
	rec_add(records, loan_term_end(date(loan_year + full_term, 6, 30)))
	ld = j['lodgement_date']
	if ld == -1:
		if oby == loan_year:
			raise MyException('lodgement_date must be specified')
	else:
		lodgement_date = datetime.strptime(ld, '%Y-%m-%d').date()
		rec_add(records, lodgement(lodgement_date))
	return full_term, principal, records


def div7a2_calculation_income_year(loan_year, term, repayments):
	"""
	find the last year in which a repayment was made, then add 1
	""" 
	if len(repayments) == 0:
		return loan_year + 1
	year = repayments[-1].income_year + 1
	last_year = loan_year + term
	if year > last_year:
		year = last_year
	while year not in benchmark_rates:
		year -= 1
		if year < 1999:
			break
	return year
