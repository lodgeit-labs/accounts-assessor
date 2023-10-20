from .div7a_impl import *


def check_invariants(records):
	"""
	this is a rather random collection at the moment. Some of them could be promoted to invariants, checked after every step, and some of them may be specific to particular phases maybe? The div7a() can eventually be simplified depending on how this turns out.
	"""

	# sanity checks:

	# - loan start is within benchmark rates range:
	
	# - calculation year is within benchmark rates range:
	
	# - lodgement day is after loan start:
	
	# - lodgement day year == loan start year + 1:
	
	# 


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
