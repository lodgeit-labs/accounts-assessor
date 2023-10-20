from .div7a_impl import *

def ensure_opening_balance_exists(records):
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



def insert_interest_accrual_records(records):

	# income year end accruals
	for income_year in income_years_of_loan(records):
				
		records.add(record(
			date(income_year, 6, 30),
			interest_accrual,
			{
				'note':'for period until income year end',
				'sorting':{'goes_before_any': [opening_balance]},
				'rate': benchmark_rate(income_year),
			}))

	# accruals before each repayment
	for repayment in repayments(records):
		records.add(record(
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
			if records[j].__class__ in [interest_accrual, opening_balance]:
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
				else:
					r.final_balance = prev_balance
				# also note interest accrual, but in div7a, interest does not add to balance.
				if r.__class__ == interest_accrual:
					r.info['interest_accrued'] = prev_balance + interest_accrued(prev_balance, r)




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


		repayments = [r for i,r in records_of_income_year(records, income_year) if r.__class__ == repayment]

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
	"""

	loan_start = get_loan_start_record(records)

	for i in range(len(records)):
		r = records[i]
		if r.__class__ == myr_check:

			if r.income_year == loan_start.income_year + 1:
				previous_income_year_final_balance = get_loan_start_year_final_balance_for_myr_calc(records)
			else:
				previous_income_year_final_balance = get_final_balance_of_previous_income_year(records, i)

			br = benchmark_rate(r.income_year)
			remaining_term = get_remaining_term(records, r)

			r.info['myr_required'] = (previous_income_year_final_balance * br / 365) / (1-(1/(1+br))**remaining_term)
			#(100 * (1 - (1 + (Benchmark_Interest_Rate / 100)) ** (-Remaining_Term))). % -?

			if r.info['myr_required'] < r.info['total_repaid_for_myr_calc']:
				r.info['excess'] = r.info['total_repaid_for_myr_calc'] - r.info['myr_required']

			elif r.info['myr_required'] > r.info['total_repaid_for_myr_calc']:
				r.info['shortfall'] = r.info['myr_required'] - r.info['total_repaid_for_myr_calc']


