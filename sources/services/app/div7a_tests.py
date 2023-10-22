from app.div7a import *


def test1():
	return div7a([
		record(date(2014, 6, 30), loan_start, {'term': 7}),
		record(date(2019, 6, 30), opening_balance, {'amount': 1000}),
	])


def test2():
	return div7a([
		record(date(2014, 6, 30), loan_start, {'term': 7}),
		record(date(2014, 6, 30), opening_balance, {'amount': 1000}),
	])


def test3():
	return div7a([
		record(date(2014, 6, 30), loan_start, {'term': 7}),
		record(date(2014, 12, 30), lodgement, {}),
	])


# todo try:
#  corner cases with repayment on the same date as opening balance
#  opening balance on loan start date
#  lodgement on loan start date
