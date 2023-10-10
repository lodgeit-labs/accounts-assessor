
loan_start = 0
opening_balance = 1
interest_accrual = 2
repayment = 3




def insert_record(records, record):
	records = records[:] + [record]
	return sort_records(records)

def sort_records(records):
	
	# sort by date, then by type (so that interest accruals come before repayments)
	records = sorted(records, key=lambda r: (r.date, r.type))
	
	# make sure there is only one interest accrual record per day
	records2 = []
	for r in records:
		if len(records2) == 0:
			records2.append(r)
		elif records2[-1].type == interest_accrual and r.type == interest_accrual and records2[-1].date == r.date:
			pass
		else:
			records2.append(r)
	return records2



def test1():
	records = [
		r(date(2014,6,30), loan_start, {'term':7}),
  		r(date(2019,6,30), opening_balance, {'amount':1000}),
		
	]
	div7a(records, [])

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

		if records[i].type == interest_accrual:
			records[i].info['amount'] = interest_accrued(records, i)


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
		if records[i].type == interest_accrual and records[i+1].type == interest_accrual and records[i].date == records[i+1].date:
			raise Exception('Two interest accruals on the same day')
		
	# - zero or one opening balance:
	
	opening_balance_records = [r for r in records if r.type == opening_balance]
	if len(opening_balance_records) > 1:
		raise Exception('More than one opening balance')
	if len(opening_balance_records) == 1:
		if opening_balance_records[0].info['amount'] <= 0:
			raise Exception('Opening balance is not positive')
	
	# - opening balance is not on the same date or preceded by anything other than loan start:

	for i in range(len(records)):
		if records[i].type == opening_balance:
			if i > 0 and records[i-1].type != loan_start:
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

	for year in range(start=loan_start_year + 1, stop=loan_start_year + 1 + loan_start_record.info.term):
		records = insert_record(records, r(date(year, 6, 30), 'interest_accrual', {}))

	# insert interest accrual records before each repayment

	for record in records:
		if record.type == repayment:
			records = insert_record(records, r(record.date, 'interest_accrual', {}))
	
	
	
	





'rate': benchmark_rate(year)
[D, end],



	# start with records corresponding to repayments



#
#
# def div7a_records_continue(l):
# 	if balance(l) <= 0:
# 		return
#
# 	either first unseen repayment or year end, whicever comes first
# 	def unseen repa;ments:
# 		for i in entries:
# 			if i['type'] == 'repayment' and not i['seen']:
# 				return
#






# todo try corner cases with repayment on the same date as opening balance