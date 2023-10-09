
loan_start = 0
opening_balance = 1
interest_accrual = 2
repayment = 3



def test1():
	records = [
		r(date(2014,6,30), loan_start, {'term':7}),
  		r(date(2019,6,30), opening_balance, {'amount':1000})
	]
	div7a(records, [])

def div7a(records, repayments):

	loan_start_record = records[0]
	loan_start_year = loan_start_record.date.year

	for repayment in repayments:
		records = insert_record(records, r(repayment['date'], 'repayment', {'amount':repayment['amount']}))

	for year in range(start=loan_start_year + 1, stop=loan_start_year + 1 + loan_start_record.info.term):
		records = insert_record(records, r(date(year, 6, 30), 'interest_accrual', {'rate': benchmark_rate(year)}))



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