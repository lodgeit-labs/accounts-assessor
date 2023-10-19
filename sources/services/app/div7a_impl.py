from .div7a_records import *



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




def get_loan_start_year_final_balance_for_myr_calc(records):
	loan_start = get_loan_start_record(records)
	repaid_in_first_year_before_lodgement_day = sum([r.info['amount'] for r in repayments(records) if r.info['counts_towards_initial_balance']])
	return loan_start.info['principal'] - repaid_in_first_year_before_lodgement_day



def get_remaining_term(records, r):
	"""
	remaining term is:
		* loan term (1 to 7 years) 
		minus 
		* the number of years between:
		(
			* the end of the private company's income year in which the loan was made,
			and
			* the end of the private company's income year before 
				the income year for which the minimum yearly repayment is being worked out.
		)
	"""
	loan_start_record = get_loan_start_record(records)
	loan_term_years = loan_start_record.info['term']
	return loan_term_years - (r.income_year-1 - loan_start_record.income_year)


def get_loan_start_record(records):
	return [r for r in records if r.__class__ == loan_start][0]


def income_years_of_loan(records):
	loan_start_record = get_loan_start_record(records)
	return range(loan_start_record.income_year + 1, loan_start_record.income_year + 1 + loan_start_record.info['term'])




def get_final_balance_of_previous_income_year(records, i):
	r = records[i]
	for j in range(i-1, -1, -1):
		rj = records[j]
		if rj.income_year != r.income_year and rj.final_balance is not None:
			return rj.final_balance



# def get_last_record_of_previous_income_year(records, i):
# 	r = records[i]
# 	for j in range(i-1, -1, -1):
# 		if records[j].income_year != r.income_year:
# 			break
# 	return records[j]



def get_lodgement(records):
	for r in records:
		if r.__class__ == lodgement:
			return r


def repayments(records):
	return [r for r in records if r.__class__ == repayment]





def opening_balance_record(records):
	r = [r for r in records if r.__class__ == opening_balance]
	if len(r) == 1:
		return r[0]
	elif len(r) > 1:
		raise Exception('More than one opening balance record')



def interest_accrued(prev_balance, r):
	return r.info['days'] * r.info['rate'] * prev_balance / 365



def days_diff(d1, d2):
	return (d1 - d2).days




def lodgement_day(records):
	# find the lodgement day, if any

	for r in records:
		if r.__class__ == lodgement:
			return r.date

	return None



def records_in_income_year(records, income_year):
	return [r for r in records if r.income_year == income_year]





def inclusive_range(start, end, step=1):
	return range(start, end + step, step)




def get_myr_check_of_income_year(records, income_year):
	return one([r for r in records if r.income_year == income_year and r.__class__ == myr_check])



def one(xs):
	if len(xs) != 1:
		raise Exception(f'Expected one element, but got {len(xs)}')
	return xs[0]




def total_interest_accrued(records, iy):
	"""
	Total interest accrued in the income year, that is, how much interest must be paid. (myr always exceeds interest)
	"""
	return sum([r.info['interest_accrued'] for r in records if r.income_year == iy and r.__class__ == interest_accrual])


def total_principal_paid(records, iy):
	"""how much of what was repaid this year, was principal?"""
	total_paid = sum([r.info['amount'] for r in records if r.income_year == iy and r.__class__ == repayment]) # ? and not r.info['counts_towards_initial_balance']
	total_interest = total_interest_accrued(records, iy)
	return total_paid - total_interest


def closing_balance(records, iy):
	"""closing balance of this income year"""
	return one([r.final_balance for r in records if r.income_year == iy])




	"""
1)

	fiscal_year_atlim
	first_fiscal_year_atlim
	



	Where a repayment is made before {the private company's lodgment day for the year in which the amalgamated loan is made}, the principal amount at 1 July of the first income year after the loan is made, is not the sum total of the constituent loans at 1 July. Rather, it is the sum of the constituent loans immediately before the lodgment day. For this purpose, payments made before lodgment day are taken to have been made in the year the amalgamated loan is made.



	"""
