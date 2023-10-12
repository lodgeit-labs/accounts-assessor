from collections import OrderedDict

from div7a_records import *


def div7a(records):
	records = insert_interest_accrual_records(records)
	sanity_checks(records)
	records = with_interest_accrual_days(records)
	records = with_balance_and_accrual(records)
	annotate_repayments_with_myr_relevance(records)
	records = add_myr_checks(records)
	annotate_myr_checks_with_myr_requirement(records)
	return records



def insert_interest_accrual_records(records):

	accruals = []

	# insert year-end interest accrual records for the length of the loan

	loan_start_record = records[0]
	loan_start_year = loan_start_record.date.year

	for year in range(loan_start_year + 1, loan_start_year + 1 + loan_start_record.info['term']):
		accruals.append(r(date(year, 6, 30), interest_accrual, {}))

	# insert interest accrual records before each repayment

	for record in records:
		if record.__class__ == repayment:
			accruals.append(r(record.date, interest_accrual, {}))

	# assign interest rates

	for a in accruals:
		a.info['rate'] = benchmark_rate(a.income_year)


	return sort_records(records + accruals)



def sanity_checks(records):
	# sanity checks:

	# - no two interest accruals on the same day:

	for i in range(len(records) - 1):
		if records[i].__class__ == interest_accrual and records[i+1].__class__ == interest_accrual and records[i].date == records[i+1].date:
			raise Exception('Two interest accruals on the same day')

	# - zero or one opening balance:

	opening_balance_records = [r for r in records if r.__class__ == opening_balance]
	if len(opening_balance_records) > 1:
		raise Exception('More than one opening balance')
	if len(opening_balance_records) == 1:
		if opening_balance_records[0].info['amount'] <= 0:
			raise Exception('Opening balance is not positive')

	# - opening balance cannot be before loan start:

	for i in range(len(records)):
		r = records[i]
		if r.__class__ == opening_balance:
			if get_loan_start_record(records).date < r.date:
				raise Exception('opening balance cannot be before loan start')

	# - one loan start, not preceded by anything

	if records[0].__class__ != loan_start:
		raise Exception('Loan start is not the first record')
	for i in range(1, len(records)):
		if records[i].__class__ == loan_start:
			raise Exception('More than one loan start')




def get_last_record_of_previous_income_year(records, i):
	r = records[i]
	for j in range(i-1, -1, -1):
		if records[j].date.income_year != r.date.income_year:
			break
	return records[j].final_balance


def get_remaining_term(records, r):
	"""tests needed"""
	loan_start_record = get_loan_start_record(records)
	return loan_start_record.info['term'] - (r.date.income_year - loan_start_record.date.income_year) + 1


def get_loan_start_record(records):
	return [r for r in records if r.__class__ == loan_start][0]

def add_myr_checks(records):

	myr_checks = []

	for income_year in income_years_of_loan(records):

		records = records_in_income_year(records, income_year)
		repayments = [r for r in records if r.__class__ == repayment]

		repayments_total = sum([r.info['amount'] for r in repayments])
		repayments_towards_myr_total = sum([r.info['amount'] for r in repayments if r.info['counts_towards_myr']])

		myr_checks.append(r(
			date(income_year, 6, 30),
			myr_check,
			{
				'total_repaid_for_myr_calc': repayments_towards_myr_total,
				'total_repaid': repayments_total,}
		))

	records = sort_records(records + myr_checks)
	propagate_final_balances(records)
	return records


def annotate_repayments_with_myr_relevance(records):
	lodgement_day = lodgement_day(records)

	for r in repayments(records):
		if r.date.income_year == loan_start.income_year + 1:
			if lodgement_day is None:
				raise Exception('if we recorded any repayments that occured the first year after loan start, then we need to know the lodgement day')
			# todo test repayment *at* lodgement day. What's the legal position?
			r.info['counts_towards_myr'] = (r.date > lodgement_day)
			if not r.info['counts_towards_myr']:
				r.info['counts_towards_myr_calc_loan_start_principal'] = True
		else:
			r.info['counts_towards_myr'] = True





def opening_balance_record(records):
	r = [r for r in records if r.type == opening_balance]
	if len(r) == 0:
		return None
	elif len(r) == 1:
		return r[0]
	else:
		raise Exception('More than one opening balance record')



def with_balance_and_accrual(records):
	records = [r.copy() for r in records]

	for i in range(len(records)):
		add_balance_and_accrual(records, i)

	return records

def add_balance_and_accrual(records, i):
	r = records[i]

	# the final balance of the previous record, is the balance of the period between the previous record and this one, is this record's start balance

	# some records trivially have a final balance

	if i == 0:
		if r.__class__ == loan_start:
			if 'principal' in r.info:
				r.final_balance = r.info['principal']
			else:
				r.final_balance = None
			return
		else:
			raise Exception('First record is not loan start')
	elif records[i].__class__ == opening_balance:
		r.final_balance = r.info['amount']
		return


	# for others, we have to reference the previous record's final balance

	if i == 0:
		prev_balance = None
	else:
		prev_balance = records[i-1].final_balance

	# calculate the new balance

	if records[i].__class__ == repayment:
		r.final_balance = prev_balance - r.info['amount']

	elif records[i].__class__ == interest_accrual:
		if prev_balance is None:
			r.final_balance = None
		else:
			r.final_balance = prev_balance + interest_accrued(prev_balance, r)

	else:
		r.final_balance = prev_balance

def interest_accrued(prev_balance, r):
	return r.info['days'] * r.info['rate'] * prev_balance / 365


def with_interest_accrual_days(records):
	records = [r.copy() for r in records]

	for i in range(len(records)):
		add_interest_accrual_days(records, i)

	return records

def add_interest_accrual_days(records, i):
	""" for each interest accrual record, calculate the interest accrued since the last interest accrual record """

	r = records[i]

	if r.__class__ != interest_accrual:
		return

	# going backwards from current record,
	# find the previous interest accrual record

	prev_date = None

	for j in range(i-1, -1, -1):
		if records[j].__class__ in [interest_accrual, opening_balance, loan_start]:
			prev_date = records[j].date
			break
	if prev_date is None:
		raise Exception('No previous interest accrual record')

	r.info['days'] = days_diff(r.date, prev_date)


def days_diff(d1, d2):
	return (d1 - d2).days




def lodgement_day(records):
	# find the lodgement day, if any

	for r in records:
		if r.__class__ == lodgement:
			return r.date

	return None



def annotate_myr_checks_with_myr_requirement(records):
	"""
		https://www.ato.gov.au/uploadedImages/Content/Images/40557-3.gif
	"""

	for i in range(len(records)):
		r = records[i]
		if r.__class__ == myr_check:

			if r.income_year == loan_start.income_year + 1:
				previous_income_year_final_balance = get_loan_start_year_final_balance_for_myr_calc(records)
			else:
				previous_income_year_final_balance = get_last_record_of_previous_income_year(records, i).final_balance

			cybir = benchmark_rate(r.date.income_year)
			remaining_term = get_remaining_term(records, r)
			r.info['myr_required'] = (previous_income_year_final_balance * cybir / 365) / (1-(1/(1+cybir))**remaining_term)
			#(100 * (1 - (1 + (Benchmark_Interest_Rate / 100)) ** (-Remaining_Term))). % -?

			if r.info['myr_required'] < r.info['total_repaid_for_myr_calc']:
				r.info['excess'] = r.info['total_repaid_for_myr_calc'] - r.info['myr_required']
			elif r.info['myr_required'] > r.info['total_repaid_for_myr_calc']:
				r.info['shortfall'] = r.info['myr_required'] - r.info['total_repaid_for_myr_calc']


def get_loan_start_year_final_balance_for_myr_calc(records):
	loan_start_record = get_loan_start_record(records)
	repaid_in_first_year_after_loan_start_before_lodgement_day = sum([r.info['amount'] for r in records if r.__class__ == repayment and r.info['counts_towards_myr_calc_loan_start_principal']])
	return (
		loan_start_record.info['principal'] -
		repaid_in_first_year_after_loan_start_before_lodgement_day)

