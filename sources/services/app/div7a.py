from div7a_records import *
from datetime import date

def div7a(records):
	records = insert_interest_accrual_records(records)
	sanity_checks(records)

	# assign each interest accrual record its interest rate

	for r in records:
		if r.type == interest_accrual:
			r.info['rate'] = benchmark_rate(r.date.year)

	# for each interest accrual record, calculate the interest accrued since the last interest accrual record

	for i in range(len(records) + 1):
		add_interest_accrual_days(records, i)

	for i in range(len(records) + 1):
		add_balance_and_accrual(records, i)


def add_balances_and_accruals(records, i):
	r = records[i]

	# the final balance of the previous record, is the balance of the period between the previous record and this one, is this record's start balance

	# some records trivially have a final balance

	if i == 0:
		if r.type == loan_start:
			if 'principal' in r.info:
				r.final_balance = r.info['principal']
			else:
				r.final_balance = None
			return
		else:
			raise Exception('First record is not loan start')
	elif records[i].type == opening_balance:
		r.final_balance = r.info['amount']
		return


	# for others, we have to reference the previous record's final balance

	if i == 0:
		prev_balance = None
	else:
		prev_balance = records[i-1].final_balance

	# calculate the new balance

	if records[i].type == repayment:
		r.final_balance = prev_balance - r.info['amount']

	elif records[i].type == interest_accrual:
		r.final_balance = prev_balance + interest_accrued(prev_balance, r)

	else:
		raise Exception('Unknown record type')

def interest_accrued(prev_balance, r):
	return r.info['days'] * r.info['rate'] * prev_balance / 365


def add_interest_accrual_days(records, i):
	r = records[i]

	# going backwards from current record,
	# find the previous interest accrual record

	prev_date = None

	for j in range(i-1, -1, -1):
		if records[j].type in ['interest_accrual', 'opening_balance', 'loan_start']:
			prev_date = records[j].date
			break
	if prev_date is None:
		raise Exception('No previous interest accrual record')

	r.info['days'] = days_diff(r.date, prev_date)
	r.info['rate'] = benchmark_rate(r.date.year)

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
	
	# - opening balance is not on the same date or preceded by anything other than loan start:

	for i in range(len(records)):
		if records[i].__class__ == opening_balance:
			if i > 0 and records[i-1].__class__ != loan_start:
				raise Exception('Opening balance is not preceded by loan start')
			if i > 0 and records[i-1].date == records[i].date:
				raise Exception('Opening balance is on the same date as something else')
		
	# - one loan start, not preceded by anything

	if records[0].type != loan_start:
		raise Exception('Loan start is not the first record')
	for i in range(1, len(records)):
		if records[i].type == loan_start:
			raise Exception('More than one loan start')



def insert_interest_accrual_records(records):
	# insert year-end interest accrual records for the length of the loan

	loan_start_record = records[0]
	loan_start_year = loan_start_record.date.year

	for year in range(loan_start_year + 1, loan_start_year + 1 + loan_start_record.info['term']):
		records = insert_record(records, r(date(year, 6, 30), interest_accrual, {}))

	# insert interest accrual records before each repayment

	for record in records:
		if record.__class__ == repayment:
			records = insert_record(records, r(record.date, interest_accrual, {}))

	return records

