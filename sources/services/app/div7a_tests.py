from div7a import *

def test1():
	return div7a([
		r(date(2014,6,30), loan_start, {'term':7}),
  		r(date(2019,6,30), opening_balance, {'amount':1000}),
	])

def test2():
	records = [
		r(date(2014,6,30), loan_start, {'term':7}),
  		r(date(2014,6,30), opening_balance, {'amount':1000}),

	]
	print(div7a(records))


def test3():
	records = [
		r(date(2014,6,30), loan_start, {'term':7}),
  		r(date(2014,12,30), lodgement, {}),
	]
	print(div7a(records))


# test1()
# test2()
# test3()


# todo try:
#  corner cases with repayment on the same date as opening balance
#  opening balance on loan start date
#  lodgement on loan start date


##  hmm, do we want to model accruals before opening balance? sorting is a problem here, as opening balance always comes first