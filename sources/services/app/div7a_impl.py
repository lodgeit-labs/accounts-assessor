import calendar
from dataclasses import dataclass


from .div7a_records import *
import logging

log = logging.getLogger(__name__)


class MyException(Exception):
	pass


def rec_add(recs, rec):
	
	"""
	add the record, sort the list, then make sure that all goes_before relations are honored.	
	 
	"""
		
	recs.append(rec)
	recs.sort()
	
	modified = True
	
	while modified:
		#log.warn(rec)
		modified = False
		
		for i,r in enumerate(recs):
			goes_before = r.info.get('sorting', {}).get('goes_before')
			if goes_before is not None:
				j = i + 1
				if len(recs) <= j or recs[j] != goes_before:
					recs.remove(r)
					recs.insert(recs.index(goes_before), r)
					modified = True
					break


@dataclass
class IdxAndRec:
	idx: Record
	rec: object



benchmark_rates = {
	2024: 8.27,
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



def benchmark_rate(year):
	try:
		return benchmark_rates[year]
	except KeyError:
		raise MyException(f'No benchmark rate for year {year}')



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
	result = loan_term_years - ((r.income_year - 1) - loan_start_record.income_year)
	return result


def get_loan_start_record(records):
	return one([r for r in records if r.__class__ == loan_start])


def income_years_of_loan(records):
	loan_start_record = get_loan_start_record(records)
	first_year = loan_start_record.income_year + 1# "fiyaiyols"
	loan_term = loan_start_record.info['term']

	# income year end accruals
	for income_year in inclusive_range(first_year, first_year + loan_term - 1):
		if income_year > loan_start_record.info['calculation_income_year']:
			return
		yield income_year


def overview_income_years(records):
	loan_start_record = get_loan_start_record(records)
	first_year = loan_start_record.income_year + 1
	

def get_final_balance_of_previous_income_year(records, i):
	"""
	find final_balance_of_previous_income_year, given index of current record
	"""
	r = records[i]
	for j in range(i-1, -1, -1):
		rj = records[j]
		if rj.income_year != r.income_year and rj.final_balance is not None:
			return rj.final_balance



def loan_agr_year_opening_balance(records, income_year):
	i = records_of_income_year_indexed(records, income_year)[0].idx
	prev = i - 1
	if prev < 0:
		# prev = 0 # technically, this is correct, but we don't want to do this, because it's a weird notion that year 0 has any opening balance
		raise MyException('not expected to be called on income year of loan creation')
	return max(0,records[prev].final_balance)


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
		raise MyException('More than one opening balance record')


def get_year_days(year):
	return 366 if calendar.isleap(year) else 365
	


def interest_accrued(prev_balance, r):
	return (prev_balance *
			# rate in percent: 5.5% -> 0.05, 100% would be 1, one year with 100% interest rate would have you paying back twice as much as you borrowed	
			(r.info['rate']/100) * 
			# but what fraction of the year did you have the loan for? one month is about a 1/12 of year
			(r.info['days'] / get_year_days(r.income_year)))



def days_diff(d1: date, d2: date) -> int:
	return (d1 - d2).days




def lodgement_day(records):
	"""
	find the lodgement day, if any
	"""

	for r in records:
		if r.__class__ == lodgement:
			return r.date

	return None



def records_of_income_year_indexed(records, income_year):
	return [IdxAndRec(i,r) for i,r in enumerate(records) if r.income_year == income_year]


def records_of_income_year(records, income_year):
	return [r for r in records if r.income_year == income_year]


def total_repayment_in_income_year(records, income_year):
	return sum([r.info['amount'] for r in records if r.income_year == income_year and r.__class__ == repayment])


def inclusive_range(start, end, step=1):
	return range(start, end + step, step)




def get_myr_check_of_income_year(records, income_year):
	return one([r for r in records if r.income_year == income_year and r.__class__ == myr_check])




def total_interest_accrued(records, iy):
	"""
	Total interest accrued in the income year, that is, how much interest must be paid. (myr always exceeds this)
	"""
	return sum([r.info['interest_accrued'] for r in records if r.income_year == iy and r.__class__ in [interest_calc, closing_interest_calc]])


def total_principal_paid(records, iy):
	"""how much of what was repaid this year, was principal?"""
	total_paid = sum([r.info['amount'] for r in records if r.income_year == iy and r.__class__ == repayment]) # ? and not r.info['counts_towards_initial_balance']
	total_interest = total_interest_accrued(records, iy)
	return max(0, total_paid - total_interest)


def closing_balance(records, iy):
	"""
	closing balance of this income year.
	This is only a reporting / output function, not affecting the computation.

	per ato calc, closing balance is not the same as the final balance of the last record of the income year.
	the closing balance is lowered by the unpaid interest. This means that the unpaid interest is not taken into account, it is effectively de-accrued. This situation can only happen when the myr is not met, so the computation is over. 
	(iow, interest is not taken into account when the loan is deemed not div7a?)
	"""
	r = list(filter(lambda r: r.final_balance is not None, records_of_income_year(records, iy)))
	fb = r[-1].final_balance
	ui = unpaid_interest(records, iy)
	return max(0,fb - ui)


def unpaid_interest(records, iy):
	total_paid = sum([r.info['amount'] for r in records if r.income_year == iy and r.__class__ == repayment])
	total_interest = total_interest_accrued(records, iy)
	return max(0, total_interest - total_paid)


def one(xs):
	if len(xs) != 1:
		raise MyException(f'Expected one element, but got {len(xs)}')
	return xs[0]


