from div7a_records import *



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


def check_invariants(records):
	"""
	this is a rather random collection at the moment. Some of them could be promoted to invariants, checked after every step, and some of them may be specific to particular phases maybe? The div7a() can eventually be simplified depending on how this turns out.	
	"""

	# sanity checks:

	# - no two interest accruals on the same day:

	for i in range(len(records) - 1):
		if records[i].__class__ == interest_accrual and records[i + 1].__class__ == interest_accrual and records[
			i].date == records[i + 1].date:
			raise Exception('Two adjacent interest accruals on the same day')

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
			if get_loan_start_record(records).date > r.date:
				raise Exception('opening balance cannot be before loan start')

	# - loan start is first record:

	if records[0].__class__ != loan_start:
		raise Exception('Loan start is not the first record')
	for i in range(1, len(records)):
		if records[i].__class__ == loan_start:
			raise Exception('More than one loan start')


def insert_interest_accrual_records(records):
	
	loan_start_record = get_loan_start_record(records)
	loan_start_iy = loan_start_record.income_year
	first_year = loan_start_iy + 1
	loan_term = loan_start_record.info['term']
	
	for income_year in inclusive_range(first_year, first_year + loan_term):
		records.add(r(
			date(income_year, 6, 30),
			interest_accrual,
			{
				'note':'for period until income year end', 
				'sorting':{'goes_before_any': [opening_balance]},
				'rate': benchmark_rate(income_year),
			}))

	for repayment in repayments(records):
		records.add(r(
			repayment.date, 
			interest_accrual,
			{
				'note':'for period until repayment',
				'rate': benchmark_rate(repayment.income_year)
			}))
		


def with_interest_accrual_days(records):
	""" 
	for each interest accrual record, calculate the accrual period since the last interest accrual or other significant event, by going backwards from the record.
	"""
	for i in range(len(records)):
		r = records[i]
		if r.__class__ != interest_accrual:
			continue
	
		prev_event_date = None
	
		for j in inclusive_range(i-1, 0, -1):
			if records[j].__class__ in [interest_accrual, opening_balance, loan_start]:
				prev_event_date = records[j].date
				break

		if prev_event_date is None:
			raise Exception('No previous interest accrual record')
		else:	
			r.info['days'] = days_diff(r.date, prev_event_date)



def with_balance_and_accrual(records):
	"""
	the final balance of the previous record, is the balance of the period between the previous record and this one, is this record's start balance
	"""

	for i in range(len(records)):
		r = records[i]
	
		# some records trivially have a final balance
		
		if r.__class__ == loan_start:
			r.final_balance = r.info.get('principal')
			continue

		if r.__class__ == opening_balance:
			r.final_balance = r.info['amount']
			continue
	
	
		# for others, we have to reference the previous record's final balance
	
		if i != 0:
			prev_balance = records[i-1].final_balance

			# if we are going through the dummy records before opening balance, then there is no previous balance, and we cannot calculate anything
			if prev_balance is not None:
	
				# calculate the new balance
	
				if r.__class__ == interest_accrual:
					r.final_balance = prev_balance + interest_accrued(prev_balance, r)
				elif r.__class__ == repayment:
					r.final_balance = prev_balance - r.info['amount']
				else:
					r.final_balance = prev_balance
					



def annotate_repayments_with_myr_relevance(records):
	
	lodgement = get_lodgement(records)

	for r in repayments(records):
		
		# if this is the first year
		if r.income_year == loan_start.income_year + 1:
		
			if lodgement is None:
				raise Exception('if we recorded any repayments that occured the first year after loan start, then we need to know the lodgement day')

			if r.date <= lodgement.date:
				r.info['counts_towards_myr_principal'] = True




def with_myr_checks(records):

	myr_checks = []

	for income_year in income_years_of_loan(records):
		repayments = [r for r in records_in_income_year(records, income_year) if r.__class__ == repayment]

		repayments_total = sum([r.info['amount'] for r in repayments])
		repayments_towards_myr_total = sum([r.info['amount'] for r in repayments if not r.info['counts_towards_myr_principal']])

		myr_checks.append(r(
			date(income_year, 6, 30),
			myr_check,
			{
				'total_repaid_for_myr_calc': repayments_towards_myr_total,
				'total_repaid': repayments_total,}
		))

	for r in myr_checks:
		records.add(r)




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
	return loan_term_years - (r.date.income_year - loan_start_record.date.income_year)


def get_loan_start_record(records):
	return [r for r in records if r.__class__ == loan_start][0]


def income_years_of_loan(records):
	loan_start_record = get_loan_start_record(records)
	return range(loan_start_record.date.income_year + 1, loan_start_record.date.income_year + 1 + loan_start_record.info['term'])

def get_last_record_of_previous_income_year(records, i):
	r = records[i]
	for j in range(i-1, -1, -1):
		if records[j].income_year != r.income_year:
			break
	return records[j]



def get_lodgement(records):
	for r in records:
		if r.__class__ == lodgement:
			return r


def repayments(records):
	return [r for r in records if r.__class__ == repayment]





def opening_balance_record(records):
	r = [r for r in records if r.type == opening_balance]
	if len(r) == 0:
		return None
	elif len(r) == 1:
		return r[0]
	else:
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



def get_loan_start_year_final_balance_for_myr_calc(records):
	loan_start_record = get_loan_start_record(records)
	repaid_in_first_year_after_loan_start_before_lodgement_day = sum([r.info['amount'] for r in records if r.__class__ == repayment and r.info['counts_towards_myr_calc_loan_start_principal']])
	return (
			loan_start_record.info['principal'] -
			repaid_in_first_year_after_loan_start_before_lodgement_day)



def inclusive_range(start, end, step=1):
	return range(start, end + 1, step)