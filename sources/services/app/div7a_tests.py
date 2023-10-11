from div7a import *

def test1():
	records = [
		r(date(2014,6,30), loan_start, {'term':7}),
  		r(date(2019,6,30), opening_balance, {'amount':1000}),

	]
	div7a(records)




test1()







# todo try corner cases with repayment on the same date as opening balance