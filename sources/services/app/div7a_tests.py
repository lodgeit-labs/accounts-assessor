

from app.div7a import *

# div7a2

#div7a2_from_json({"loan_year": 2020, "full_term": 7, "opening_balance": 100000.0, "opening_balance_year": 2020, "repayments": [{"date": "2023-11-25", "amount": 0.0}], "lodgement_date": "2021-06-30"})
div7a2_from_json({"loan_year": 2020, "full_term": 7, "opening_balance": 100000.0, "opening_balance_year": 2020, "repayments": [{"date": "2021-06-30", "amount": 10000.0}, {"date": "2022-06-30", "amount": 10000.0}, {"date": "2023-06-30", "amount": 10000.0}, {"date": "2024-06-30", "amount": 10000.0}, {"date": "2025-06-30", "amount": 10000.0}, {"date": "2026-06-30", "amount": 10000.0}, {"date": "2027-06-30", "amount": 10000.0}], "lodgement_date": "2021-06-30"})


#div7a2_from_json({"loan_year": 2020, "full_term": 7, "opening_balance": 100000.0, "opening_balance_year": 2020, "repayments": [{"date": "2023-11-25", "amount": 0.0}], "lodgement_date": "2021-06-30"})





# div7a

div7a_from_json({'computation_income_year': '1999', 'creation_income_year': '1998', 'lodgement_date': '1999-02-04', 'opening_balance': '298', 'principal_amount': -1, 'repayments': [], 'term': '1'})


try:
	div7a_from_json({
		"computation_income_year": "2009",
		"creation_income_year": "2008",
		"lodgement_date": "2009-07-01",
		"opening_balance": "10379",
		"principal_amount": -1,
		"repayments": [
			{
				"date": "2009-02-07",
				"value": "41994"
			},
			{
				"date": "2009-03-30",
				"value": "2453"
			},
			{
				"date": "2009-05-20",
				"value": "21484"
			},
			{
				"date": "2009-11-05",
				"value": "7504"
			},
			{
				"date": "2010-09-19",
				"value": "18547"
			},
			{
				"date": "2010-11-08",
				"value": "15763"
			},
			{
				"date": "2011-04-12",
				"value": "37391"
			},
			{
				"date": "2011-05-15",
				"value": "6338"
			},
			{
				"date": "2011-12-01",
				"value": "31469"
			},
			{
				"date": "2012-02-15",
				"value": "21277"
			},
			{
				"date": "2012-06-09",
				"value": "8549"
			},
			{
				"date": "2012-10-08",
				"value": "9038"
			}
		],
		"term": "4"
	})
except Exception as e:
	assert str(e) == 'lodgement day income year != loan start income year + 1: 2010 != 2008 + 1'

try:
  div7a_from_json({
   "computation_income_year": "2019",
   "creation_income_year": "2018",
   "lodgement_date": "2019-03-24",
   "opening_balance": "24492",
   "principal_amount": -1,
   "repayments": [
	{
	 "date": "2018-07-13",
	 "value": "20630"
	},
	{
	 "date": "2019-01-30",
	 "value": "8209"
	},
	{
	 "date": "2020-02-25",
	 "value": "41652"
	},
	{
	 "date": "2020-07-14",
	 "value": "26634"
	},
	{
	 "date": "2021-06-22",
	 "value": "9314"
	},
	{
	 "date": "2022-04-22",
	 "value": "9665"
	},
	{
	 "date": "2022-11-14",
	 "value": "20060"
	},
	{
	 "date": "2023-08-02",
	 "value": "3922"
	},
	{
	 "date": "2023-10-24",
	 "value": "8217"
	},
	{
	 "date": "2023-12-31",
	 "value": "31515"
	},
	{
	 "date": "2024-12-26",
	 "value": "42067"
	}
   ],
   "term": "6"
  })
except Exception as e:
	assert str(e) == 'No benchmark rate for year 2025'

try:
	div7a_from_json({"computation_income_year": "2017", "creation_income_year": "2014", "lodgement_date": "2015-05-15", "opening_balance": -1, "principal_amount": "50000.00", "repayments": [{"date": "2014-08-31", "value": "20000.00"}, {"date": "2015-05-30", "value": "8000.00"}, {"date": "2016-05-30", "value": "8000.00"}], "term": "2"})
except Exception as e:
	assert str(e) == 'calculation starts after loan_term_end'

try:
	div7a_from_json({"computation_income_year": "2015", "creation_income_year": "2014", "lodgement_date": -1, "opening_balance": -1, "principal_amount": "50000.00", "repayments": [{"date": "2014-08-31", "value": "20000.00"}, {"date": "2015-05-30", "value": "8000.00"}], "term": "7"})
except Exception as e:
	assert str(e) == 'if we recorded any repayments that occurred the first year after loan start, then we need to know the lodgement day to calculate minimum yearly repayment.'

try:
	div7a_from_json({"computation_income_year": "2019", "creation_income_year": "2018", "lodgement_date": "2019-03-24", "opening_balance": "24492", "principal_amount": -1, "repayments": [{"date": "2018-07-23", "value": "20613"}, {"date": "2018-08-04", "value": "20630"}, {"date": "2019-02-21", "value": "8209"}, {"date": "2020-03-18", "value": "41652"}, {"date": "2020-08-05", "value": "26634"}, {"date": "2021-07-14", "value": "9314"}, {"date": "2022-05-14", "value": "9665"}, {"date": "2022-12-06", "value": "20060"}, {"date": "2023-08-24", "value": "3922"}, {"date": "2023-11-15", "value": "8217"}, {"date": "2024-01-22", "value": "31515"}, {"date": "2025-01-17", "value": "42067"}], "term": "6"})
except Exception as e:
	assert str(e) == 'No benchmark rate for year 2025'


# todo try:
#  corner cases with repayment on the same date as opening balance
# - this is probably well covered by atocalc-generated testcases. There is also no such thing as a date of opening balance, opening balance always applies to the start of the income year.
#  opening balance on loan start date
# - ditto
#  lodgement on loan start date
