from .div7a_impl import *


def check_invariants(records):

	# - lodgement day year == loan start year + 1:
	
	lodgement_day_records = [r for r in records if r.__class__ == lodgement]
	if len(lodgement_day_records) > 1:
		raise MyException('More than one lodgement day')
	if len(lodgement_day_records) == 1:
		if lodgement_day_records[0].income_year != get_loan_start_record(records).income_year + 1:
			raise MyException(f'lodgement day income year != loan start income year + 1: {lodgement_day_records[0].income_year} != {get_loan_start_record(records).income_year} + 1')

	# - loan start is first record:

	if records[0].__class__ != loan_start:
		raise MyException('Loan start is not the first record')
	for i in range(1, len(records)):
		if records[i].__class__ == loan_start:
			raise MyException('More than one loan start')

	# - opening balance cannot be before loan start:

	for i in range(len(records)):
		r = records[i]
		if r.__class__ == opening_balance:
			if get_loan_start_record(records).date > r.date:
				raise MyException('opening balance cannot be before loan start')

	# - zero or one opening balance:

	opening_balance_records = [r for r in records if r.__class__ == opening_balance]
	if len(opening_balance_records) > 1:
		raise MyException('More than one opening balance')
	if len(opening_balance_records) == 1:
		if opening_balance_records[0].info['amount'] <= 0:
			raise MyException('Opening balance is not positive')

	# 	loan_start is before calculation_start:
	
	if records.index(one([r for r in records if r.__class__ == calculation_start])) <= records.index(one([r for r in records if r.__class__ == loan_start])):
		raise MyException('loan_start is before calculation_start')

	if records.index(one([r for r in records if r.__class__ == calculation_start])) >= records.index(one([r for r in records if r.__class__ == loan_term_end])):
		raise MyException('calculation starts after loan_term_end')

	if records.index(one([r for r in records if r.__class__ == calculation_end])) >= records.index(one([r for r in records if r.__class__ == loan_term_end])):
		raise MyException('loan_term_end is before calculation_end')

	if records.index(one([r for r in records if r.__class__ == calculation_start])) >= records.index(one([r for r in records if r.__class__ == calculation_end])):
		raise MyException('calculation_end is before calculation_start')

	# - no two adjacent interest calcs on the same day:

	for i in range(len(records) - 1):
		if records[i].__class__ == interest_calc and records[i + 1].__class__ == interest_calc and records[
			i].date == records[i + 1].date:
			raise MyException('Two adjacent interest calcs on the same day')

	# - repayments must be positive amounts:
	for r in repayments(records):
		if r.info['amount'] <= 0:
			raise MyException('Repayment is not positive')
	
	# - repayments cannot be before opening balance
	for r in records:
		if r.__class__ == opening_balance:
			break
		elif r.__class__ == repayment:
			raise MyException('Repayment before opening balance')
			