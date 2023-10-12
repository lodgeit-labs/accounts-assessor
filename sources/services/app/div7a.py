from div7a_records import *
from datetime import date

def benchmark_rate(year):
	rates = {
		2023: 4.77,
		2022: 4.52,
		2021: 4.52,
		2020: 5.37,
		2019: 5.20,
		2018: 5.30,
		2017: 5.40,
		2016: 5.45,
		2015: 5.95,
		2014: 6.20,
		2013: 7.05,
		2012: 7.80,
		2011: 7.40,
		2010: 5.75,
		2009: 9.45,
		2008: 8.05,
		2007: 7.55,
		2006: 7.3,
		2005: 7.05,
		2004: 6.55,
		2003: 6.3,
		2002: 6.8,
		2001: 7.8,
		2000: 6.5,
		1999: 6.7,
	}
	return rates[year]

def div7a(records):
	records = insert_interest_accrual_records(records)
	sanity_checks(records)

	# assign each interest accrual record its interest rate

	for r in records:
		if r.__class__ == interest_accrual:
			r.info['rate'] = benchmark_rate(r.date.year)

	# for each interest accrual record, calculate the interest accrued since the last interest accrual record

	for i in range(len(records)):
		add_interest_accrual_days(records, i)

	for i in range(len(records)):
		add_balance_and_accrual(records, i)

	records = add_myr_checks(records)

	return records



def lodgement_day(records):
	# find the lodgement day, if any

	for r in records:
		if r.__class__ == lodgement:
			return r.date

	return None


def add_myr_checks(records):

	lodgement_day = lodgement_day(records)

	for r in repayments(records):

		if r.date.income_year == loan_start.income_year + 1:

		if lodgement_day is None:
			raise Exception('if we recorded any repayments that occured the first year after loan start, then we need to know the lodgement day')

		r.info['counts_towards_myr'] = (r.date > lodgement_day)



	for year in loan_years(records):
		year_records = records_in_year(records, year)
		year_repayments = [r for r in year_records if r.__class__ == repayment]
		year_repayments_after_lodgement_day = [r for r in year_repayments if r.date > lodgement_day]



		year_repayments_total = sum([r.info['amount'] for r in year_repayments if r.info['])










	total_repaid_this_year = 0
	year = records[0].date.year

	for i in range(len(records)):
		r = records[i]
		if r.date.year != year:
				records = insert_record(records, r(date(year, 6, 30), myr_check, {'total_repaid': total_repaid_this_year}))
				year = r.date.year
				total_repaid_this_year = 0

		if r.__class__ == repayment:
			total_repaid_this_year += r.info['amount']




def opening_balance_record(records):
	r = [r for r in records if r.type == opening_balance]
	if len(r) == 0:
		return None
	elif len(r) == 1:
		return r[0]
	else:
		raise Exception('More than one opening balance record')


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
		raise Exception('Unknown record type')

def interest_accrued(prev_balance, r):
	return r.info['days'] * r.info['rate'] * prev_balance / 365


def add_interest_accrual_days(records, i):
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
	r.info['rate'] = benchmark_rate(r.date.year)


def days_diff(d1, d2):
	return (d1 - d2).days

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
	
	# # - opening balance is not on the same date or preceded by anything other than loan start:
	#
	# for i in range(len(records)):
	# 	if records[i].__class__ == opening_balance:
	# 		if i > 0 and records[i-1].__class__ != loan_start:
	# 			raise Exception('Opening balance is not preceded by loan start')
	# 		if i > 0 and records[i-1].date == records[i].date:
	# 			raise Exception('Opening balance is on the same date as something else')
		
	# - one loan start, not preceded by anything

	if records[0].__class__ != loan_start:
		raise Exception('Loan start is not the first record')
	for i in range(1, len(records)):
		if records[i].__class__ == loan_start:
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

