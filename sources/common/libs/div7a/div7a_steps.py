from datetime import timedelta
from .div7a_impl import *



def ensure_opening_balance_exists(records):
	"""
	opening balance is either:
	* provided explicitly by user (implied to be the opening balance of the computation income year), 
	* or it is implied by loan princial (on the last day of loan start income year).
	in either case, there will be one opening balance record, and it will be on the last day of the computation income year.
	"""

	opening_balance_rec = opening_balance_record(records)
	if opening_balance_rec is None:
		loan_start_rec = get_loan_start_record(records)
		rec_add(records, record(
			date(loan_start_rec.income_year, 6, 30),
			opening_balance,
			{
				'amount': loan_start_rec.info['principal']
			}
		))



def insert_interest_calc_records(records):

	# before each repayment
	for repayment in repayments(records):
		rec_add(records, record(
			repayment.date,
			interest_calc,
			{
				'note': 'for period up until repayment',
				'sorting': {'goes_before': repayment},
				'rate': benchmark_rate(repayment.income_year)
			}))

	# income year end
	for income_year in income_years_of_loan(records):
				
		if income_year not in benchmark_rates:
			break

		iy_end = record(
			date(income_year, 6, 30),
			income_year_end,
			{}
		)
		rec_add(records, iy_end)
				
		rec_add(records, record(
			date(income_year, 6, 30),
			closing_interest_calc,
			{
				'note':'for period until income year end',
				'sorting': {'goes_before': iy_end},
				'rate': benchmark_rate(income_year),
			}))


def with_interest_calc_days(records):
	"""
	for each interest accrual record, calculate the accrual period since the last interest accrual or other significant event, by going backwards from the record.
	"""
	for i in range(len(records)):
		r = records[i]
		
		if r.__class__ not in [interest_calc, closing_interest_calc]:
			continue

		prev_event_date = None
		for j in records_before_this_record_in_reverse_order(records, i):

			if j.__class__ in [opening_balance, loan_start, closing_interest_calc]:
				# 
				prev_event_date = j.date + timedelta(days=1)
				break
			if j.__class__ in [interest_calc]:
				prev_event_date = j.date
				break
	
		if prev_event_date is None:
			raise MyException('No previous opening_balance or interest_calc record')

		if r.__class__ is interest_calc:
			r.info['days'] = days_diff(r.date, prev_event_date)
		elif r.__class__ is closing_interest_calc:
			r.info['days'] = days_diff(r.date + timedelta(days=1), prev_event_date)
			


def records_before_this_record_in_reverse_order(records, i):
	for j in inclusive_range(i-1, 0, -1):
		yield records[j]

def with_balance(records):
	"""
	the final balance of the previous record, is the balance of the period between the previous record and this one, is this record's start balance
	"""
	for i in range(len(records)):
		r = records[i]

		# some records trivially have a final balance
		if r.__class__ == opening_balance:
			r.final_balance = r.info['amount']
			continue

		# for others, we have to reference the previous record's final balance
		if i != 0:

			prev_rec = records[i-1]
			if prev_rec.__class__ == calculation_end:
				prev_balance = None
			else:
				prev_balance = prev_rec.final_balance

			if prev_balance is not None:
				# calculate the new balance
				if r.__class__ == repayment:
					r.final_balance = prev_balance - r.info['amount']
				elif r.__class__ in [interest_calc, closing_interest_calc]:
					r.info['interest_accrued'] = round(interest_accrued(max(0,prev_balance), r), 20)
					r.final_balance = prev_balance
				elif r.__class__ == income_year_end:
					periods = [c.info['interest_accrued'] for c in records_of_income_year(records, r.income_year) if c.__class__ in [interest_calc, closing_interest_calc]]
					r.info['periods'] = len(periods)
					r.info['interest_accrued'] = sum(periods)
					r.final_balance = prev_balance + r.info['interest_accrued']
				else:
					r.final_balance = prev_balance


	
def annotate_repayments_with_myr_relevance(records):
	"""
	Where a repayment is made before {the private company's lodgment day for the year in which the amalgamated loan is made}, the principal amount at 1 July of the first income year after the loan is made, is not the sum total of the constituent loans at 1 July. Rather, it is the sum of the constituent loans immediately before the lodgment day. For this purpose, payments made before lodgment day are taken to have been made in the year the amalgamated loan is made.
	"""
	lodgement = get_lodgement(records)
	loan_start = get_loan_start_record(records)
	for r in repayments(records):
		r.info['counts_towards_initial_balance'] = False
		# but if this is the first year
		if r.income_year == loan_start.income_year + 1:
			if lodgement is None:
				raise MyException('if we recorded any repayments that occurred the first year after loan start, then we need to know the lodgement day to calculate minimum yearly repayment.')
			if r.date < lodgement.date:
				r.info['counts_towards_initial_balance'] = True



def with_myr_checks(records):

	myr_checks = []

	for income_year in income_years_of_loan(records):

		# skip checks before opening balance:
		if opening_balance_record(records).income_year >= income_year:
			# no myr check for year of opening balance either. But this relies on the fact that opening balance is set on the last day of the preceding income year.
			continue

		if income_year < benchmark_rate_years()[0]:
			raise MyException('Cannot calculate before income year {}'.format(benchmark_rate_years()[0]))

		# skip checks in future
		if income_year > benchmark_rate_years()[-1]:
			break

		repayments = [r for r in records_of_income_year(records, income_year) if r.__class__ == repayment]

		repayments_total = sum([r.info['amount'] for r in repayments])
		repayments_towards_myr_total = sum([r.info['amount'] for r in repayments if not r.info['counts_towards_initial_balance']])

		myr_checks.append(record(
			date(income_year, 6, 30),
			myr_check,
			{
				'total_repaid_for_myr_calc': repayments_towards_myr_total,
				'total_repaid': repayments_total
			}
		))

	for r in myr_checks:
		rec_add(records, r)
		
	for i,r in enumerate(records):
		if r.__class__ is myr_check:
			r.final_balance = records[i-1].final_balance
		
		



def evaluate_myr_checks(records):
	"""
	https://www.ato.gov.au/uploadedImages/Content/Images/40557-3.gif
	
	calculate required payment for each year, and compare to actual payment.
	"""

	loan_start = get_loan_start_record(records)

	for i in range(len(records)):
		r = records[i]
		if r.__class__ == myr_check:

			fb = get_final_balance_of_previous_income_year(records, i)

			if r.income_year == loan_start.income_year + 1:
				repaid_in_first_year_before_lodgement_day = sum(
					[r.info['amount'] for r in repayments(records) if r.info['counts_towards_initial_balance']]
				)
				previous_income_year_final_balance = fb - repaid_in_first_year_before_lodgement_day
			else:
				previous_income_year_final_balance = fb

			br = benchmark_rate(r.income_year)
			remaining_term = get_remaining_term(records, r)

			r.info['myr_check_previous_income_year_final_balance'] = previous_income_year_final_balance
			r.info['myr_required'] = ((previous_income_year_final_balance * (br/100)) /
									  (1-(1/(1+(br/100)))**remaining_term))
			
			#if r.info['myr_required'] < r.info['total_repaid_for_myr_calc']:
			r.info['excess'] = max(0, r.info['total_repaid'] - r.info['myr_required'])

			#elif r.info['myr_required'] > r.info['total_repaid_for_myr_calc']:
			r.info['shortfall'] = max(0, r.info['myr_required'] - r.info['total_repaid'])
			

