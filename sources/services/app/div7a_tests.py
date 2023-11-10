

from app.div7a import *

div7a_from_json({'computation_income_year': '1999', 'creation_income_year': '1998', 'lodgement_date': '1999-02-04', 'opening_balance': '298', 'principal_amount': -1, 'repayments': [], 'term': '1'})

div7a_from_json({"computation_income_year": "2017", "creation_income_year": "2014", "lodgement_date": "2015-05-15", "opening_balance": -1, "principal_amount": "50000.00", "repayments": [{"date": "2014-08-31", "value": "20000.00"}, {"date": "2015-05-30", "value": "8000.00"}, {"date": "2016-05-30", "value": "8000.00"}], "term": "2"})

div7a_from_json({"computation_income_year": "2015", "creation_income_year": "2014", "lodgement_date": -1, "opening_balance": -1, "principal_amount": "50000.00", "repayments": [{"date": "2014-08-31", "value": "20000.00"}, {"date": "2015-05-30", "value": "8000.00"}], "term": "7"})

# todo try:
#  corner cases with repayment on the same date as opening balance
# - this is probably well covered by atocalc-generated testcases. There is also no such thing as a date of opening balance, opening balance always applies to the start of the income year.
#  opening balance on loan start date
# - ditto
#  lodgement on loan start date
