#!/usr/bin/env python3

import json, os, sys, datetime, random
from datetime import timedelta, date
from xml.etree.ElementTree import canonicalize, fromstring, tostring


random.seed(0)


from xml.dom import minidom
from xml.dom.minidom import getDOMImplementation
impl = getDOMImplementation()


from utils import *



def run():

	for loan_year in range(2000, 2020):
		start = date(loan_year, 7, 1)
		for full_term in range(2, 7):
			
			end = date(loan_year+full_term, 6, 30)

			repayments = repaymentset(start, end)
			principal = random.randint(1, 1000000)
			lodgement_date = start + timedelta(days=random.randint(0, 365))

			enquiry_year = date(loan_year, 7, 1)
			cb = principal

			while cb > 0:
				enquiry_year += 1

				last_step_result_xml_text = single_step_request(loan_year, full_term, lodgement_date, cb, repayments_for_iy(enquiry_year, repayments))
				step = fromstring(last_step_result_xml_text)

				cb2 = float(step.find('closing_balance').text)
						
				if cb2 >= cb:
					raise 'hmm'
				cb = cb2

				if float(step.find('shortfall').text) != 0:
					break
				if cb == 0:
					break
				if enquiry_year >= 2024:
					break
					
			write_multistep_testcase(loan_year, full_term, lodgement_date, principal, repayments, enquiry_year, last_step_result_xml_text)


def write_multistep_testcase(loan_year, full_term, lodgement_date, principal, repayments, enquiry_year, single_step_result_xml_text):
	request_fn = inputs_dir / 'request.xml'

	with open(request_fn, 'w') as f:

		doc = impl.createDocument(None, "reports", None)
		loan = doc.documentElement.appendChild(doc.createElement('loanDetails'))

		agreement = loan.appendChild(doc.createElement('loanAgreement'))
		repayments = loan.appendChild(doc.createElement('repayments'))

		def field(name, value):
			field = agreement.appendChild(doc.createElement('field'))
			field.setAttribute('name', name)
			field.setAttribute('value', str(value))

			field('Income year of loan creation', income_year_of_loan_creation)
			field('Full term of loan in years', full_term_of_loan_in_years)
			if lodgement_day_of_private_company is not None:
				field('Lodgement day of private company', ato_date_to_xml(lodgement_day_of_private_company))
			field('Income year of computation', income_year_of_computation)

			# maybe we could generate some testcases with principal rather than opening balance tag, it will mean the same thing.
			field('Opening balance of computation', opening_balance)
			# field('Principal amount of loan', opening_balance)

			for r in j['repayments']:
				repayment = repayments.appendChild(doc.createElement('repayment'))
				repayment.setAttribute('date', ato_date_to_xml(r['rd']))
				repayment.setAttribute('value', str(r['ra']))

			with open(request_fn, 'w') as f:
				f.write(doc.toprettyxml(indent='\t'))

		f.write(to_xml_string(dict(
			loan_year = loan_year,
			full_term = full_term,
			lodgement_date = lodgement_date,
			calc_year = enquiry_year,
			principal = principal,
			repayments = repayments,
		))

	with open(tc / 'responses' / 'response.xml', 'w') as f:
		f.write(single_step_result_xml_text)
	
	

		
	
	# 	dict(
	# 		IncomeYear = last_step['IncomeYear'],
	# 		OpeningBalance = last_step['OpeningBalance'],
	# 		InterestRate = last_step['InterestRate'],
	# 		MinYearlyRepayment = last_step['MinYearlyRepayment'],
	# 		TotalRepayment = last_step['TotalRepayment'],
	# 		RepaymentShortfall = 
	# 		TotalInterest = 
	# 		TotalPrincipal = 
	# 		ClosingBalance = 
	# 		shortfall = last_step['shortfall'],
			
			
		
		

		
	
	
	
	
	







def repaymentset(start, end_inclusive):
	
	date = start
	repayments = []

	while date <= end_inclusive:
		date += timedelta(days=random.randint(0, 400))
		repayments.append(dict(date=date, amount=random.randint(0, 50000)))
	
	return repayments









if __name__ == '__main__':
	run()
