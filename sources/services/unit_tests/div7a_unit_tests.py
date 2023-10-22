from div7a_impl import *

import pytest


class TestGetRemainingTerm:

	#  Calculate remaining term correctly when given valid input
	def test_calculate_remaining_term_valid_input(self):
		records = [
			loan_start(date(2020, 1, 1), 10000, 5),
			repayment(date(2021, 1, 1), 2000),
			repayment(date(2022, 1, 1), 2000),
			repayment(date(2023, 1, 1), 2000)
		]
		r = records[1]
		remaining_term = get_remaining_term(records, r)
		assert remaining_term == 3

	#  Return 0 when given a record from the loan start year
	def test_return_zero_loan_start_year(self):
		records = [
			loan_start(date(2020, 1, 1), 10000, 5),
			repayment(date(2020, 1, 1), 2000),
			repayment(date(2021, 1, 1), 2000),
			repayment(date(2022, 1, 1), 2000)
		]
		r = records[1]
		remaining_term = get_remaining_term(records, r)
		assert remaining_term == 0

	#  Return correct remaining term when given a record from the year after the loan start year
	def test_return_remaining_term_year_after_loan_start(self):
		records = [
			loan_start(date(2020, 1, 1), 10000, 5),
			repayment(date(2021, 1, 1), 2000),
			repayment(date(2022, 1, 1), 2000),
			repayment(date(2023, 1, 1), 2000)
		]
		r = records[1]
		remaining_term = get_remaining_term(records, r)
		assert remaining_term == 4

	#  Return correct remaining term when given a record from the year the loan ends
	def test_return_remaining_term_loan_end_year(self):
		records = [
			loan_start(date(2020, 1, 1), 10000, 5),
			repayment(date(2021, 1, 1), 2000),
			repayment(date(2022, 1, 1), 2000),
			repayment(date(2023, 1, 1), 2000)
		]
		r = records[3]
		remaining_term = get_remaining_term(records, r)
		assert remaining_term == 1

	#  Return correct remaining term when given a record from a year after the loan ends
	def test_return_remaining_term_year_after_loan_end(self):
		records = [
			loan_start(date(2020, 1, 1), 10000, 5),
			repayment(date(2021, 1, 1), 2000),
			repayment(date(2022, 1, 1), 2000),
			repayment(date(2023, 1, 1), 2000)
		]
		r = records[4]
		remaining_term = get_remaining_term(records, r)
		assert remaining_term == 0

	#  Return correct remaining term when given a record from a year before the loan start year
	def test_return_remaining_term_year_before_loan_start(self):
		records = [
			loan_start(date(2020, 1, 1), 10000, 5),
			repayment(date(2019, 1, 1), 2000),
			repayment(date(2020, 1, 1), 2000),
			repayment(date(2021, 1, 1), 2000)
		]
		r = records[1]
		remaining_term = get_remaining_term(records, r)
		assert remaining_term == -1

