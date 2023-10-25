from .div7a_impl import *



def ensure_opening_balance_exists(records):
	"""
	opening balance is either:
	* provided explicitly by user (implied to be the opening balance of the computation income year), 
	* or it is implied by loan princial (on the last day of loan start income year).
	in either case, there will be one opening balance record, and it will be on the last day of the computation income year.
	"""
	
	opening_balance = opening_balance_record(records)
	if opening_balance is None:
		loan_start = get_loan_start_record(records)
		records.add(record(
			date(loan_start.income_year, 6, 30),
			opening_balance,
			{
				'amount': loan_start.info['principal']
			}
		))



def insert_interest_calc_records(records):

	# accruals before each repayment
	for repayment in repayments(records):
		records.add(record(
			repayment.date,
			interest_calc,
			{
				'note': 'for period until repayment',
				'sorting': {'goes_before': repayment},
				'rate': benchmark_rate(repayment.income_year)
			}))

	# income year end accruals
	for income_year in income_years_of_loan(records):
				
		if income_year not in benchmark_rates:
			break

		iy_end = record(
			date(income_year, 6, 30),
			income_year_end,
			{}
		)
		records.add(iy_end)
				
		records.add(record(
			date(income_year, 6, 30),
			interest_calc,
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
		if r.__class__ != interest_calc:
			continue

		prev_event_date = None

		for j in inclusive_range(i-1, 0, -1):
			if records[j].__class__ in [interest_calc, opening_balance]:
				prev_event_date = records[j].date
				break

		if prev_event_date is None:
			raise Exception('No previous interest accrual record')
		else:
			r.info['days'] = days_diff(r.date, prev_event_date)



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
			prev_balance = records[i-1].final_balance
			if prev_balance is None:
				# if we are going through the dummy records before opening balance, then there is no previous balance, and we cannot calculate anything
				pass
			else:
				# calculate the new balance
				if r.__class__ == repayment:
					r.final_balance = prev_balance - r.info['amount']
				elif r.__class__ == interest_calc:
					# round to two decimal places as ato calc seems to be doing
					r.info['interest_accrued'] = round(interest_accrued(prev_balance, r), 2)
					r.final_balance = prev_balance
				elif r.__class__ == income_year_end:
					periods = [c.info['interest_accrued'] for c in records_of_income_year(records, r.income_year) if c.__class__ == interest_calc]
					r.info['periods'] = len(periods)
					r.info['interest_accrued'] = sum(periods)
					r.final_balance = prev_balance + r.info['interest_accrued']
				else:
					r.final_balance = prev_balance


	
def annotate_repayments_with_myr_relevance(records):
	lodgement = get_lodgement(records)
	loan_start = get_loan_start_record(records)
	for r in repayments(records):
		r.info['counts_towards_initial_balance'] = False
		# but if this is the first year
		if r.income_year == loan_start.income_year + 1:
			if lodgement is None:
				raise Exception('if we recorded any repayments that occured the first year after loan start, then we need to know the lodgement day')
			if r.date <= lodgement.date:
				r.info['counts_towards_initial_balance'] = True



def with_myr_checks(records):

	myr_checks = []

	for income_year in income_years_of_loan(records):

		# skip checks before opening balance:
		if opening_balance_record(records).income_year >= income_year:
			# no myr check for year of opening balance either. But this relies on the fact that opening balance is set on the last day of the preceding income year.
			continue

		# skip checks in future
		if income_year not in benchmark_rates:
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
		records.add(r)




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
			r.info['excess'] = min(0, r.info['total_repaid'] - r.info['myr_required'])

			#elif r.info['myr_required'] > r.info['total_repaid_for_myr_calc']:
			r.info['shortfall'] = max(0, r.info['myr_required'] - r.info['total_repaid'])
			

