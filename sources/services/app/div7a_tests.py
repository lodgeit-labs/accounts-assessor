

from app.div7a import *

div7a_from_json({'computation_income_year': '1999', 'creation_income_year': '1998', 'lodgement_date': '1999-02-04', 'opening_balance': '298', 'principal_amount': -1, 'repayments': [], 'term': '1'})

try:
	div7a_from_json({"computation_income_year": "2017", "creation_income_year": "2014", "lodgement_date": "2015-05-15", "opening_balance": -1, "principal_amount": "50000.00", "repayments": [{"date": "2014-08-31", "value": "20000.00"}, {"date": "2015-05-30", "value": "8000.00"}, {"date": "2016-05-30", "value": "8000.00"}], "term": "2"})
except Exception as e:
	assert str(e) == 'calculation starts after loan_term_endcalculation_start'

try:
	div7a_from_json({"computation_income_year": "2015", "creation_income_year": "2014", "lodgement_date": -1, "opening_balance": -1, "principal_amount": "50000.00", "repayments": [{"date": "2014-08-31", "value": "20000.00"}, {"date": "2015-05-30", "value": "8000.00"}], "term": "7"})
except Exception as e:
	assert str(e) == 'if we recorded any repayments that occured the first year after loan start, then we need to know the lodgement day to calculate minimum yearly repayment.'

try:
	div7a_from_json({"computation_income_year": "2019", "creation_income_year": "2018", "lodgement_date": "2019-03-24", "opening_balance": "24492", "principal_amount": -1, "repayments": [{"date": "2018-07-23", "value": "20613"}, {"date": "2018-08-04", "value": "20630"}, {"date": "2019-02-21", "value": "8209"}, {"date": "2020-03-18", "value": "41652"}, {"date": "2020-08-05", "value": "26634"}, {"date": "2021-07-14", "value": "9314"}, {"date": "2022-05-14", "value": "9665"}, {"date": "2022-12-06", "value": "20060"}, {"date": "2023-08-24", "value": "3922"}, {"date": "2023-11-15", "value": "8217"}, {"date": "2024-01-22", "value": "31515"}, {"date": "2025-01-17", "value": "42067"}], "term": "6"})
except Exception as e:
	assert str(e) == 'No benchmark rate for year 2025.'

# todo try:
#  corner cases with repayment on the same date as opening balance
# - this is probably well covered by atocalc-generated testcases. There is also no such thing as a date of opening balance, opening balance always applies to the start of the income year.
#  opening balance on loan start date
# - ditto
#  lodgement on loan start date
