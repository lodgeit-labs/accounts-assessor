#!/usr/bin/env python3
import io
import json, os, sys, datetime, random, requests
from datetime import timedelta, date
from pathlib import Path
from xml.etree.ElementTree import canonicalize, fromstring, tostring

from utils import python_date_to_xml

random.seed(0)


requests_session = requests.Session()
requests_adapter = requests.adapters.HTTPAdapter(max_retries=5)
requests_session.mount('http://', requests_adapter)
requests_session.mount('https://', requests_adapter)


from xml.dom import minidom
from xml.dom.minidom import getDOMImplementation
impl = getDOMImplementation()


from utils import *


def single_step_request(loan_year, full_term, lodgement_date, ob, repayments, enquiry_year):
	x = request_xml(loan_year, full_term, lodgement_date, ob, repayments, enquiry_year)
	request_str = x.toprettyxml(indent='\t')
	print(request_str)

	robust_server_url = 'http://localhost:8877'

	file1=io.StringIO(request_str)
	file1.name='request.xml'
	files = dict(file1=file1)

	return (request_str, requests_session.post(
			f'{robust_server_url}/upload',
			params={'request_format':'xml', 'requested_output_format': 'immediate_xml'},
			files=files
	).text)



def repayments_for_income_year(repayments, enquiry_year):
	for r in repayments:
		if r['date'] >= date(enquiry_year - 1, 7, 1) and r['date'] <= date(enquiry_year, 6, 30):
			yield r


def run():
	while True:
		run2()

def run2():
	for loan_year in range(2000, 2020):
		start = date(loan_year, 7, 1)
		for full_term in range(2, 7):
			
			end = date(loan_year+full_term, 6, 30)

			repayments = repaymentset(start, end)
			principal = random.randint(1, 1000000)
			lodgement_date = start + timedelta(days=random.randint(0, 365))

			enquiry_year = loan_year + 1 #date(loan_year, 7, 1)
			cb = principal

			comments = []

			while cb > 0:
				enquiry_year += 1#date(enquiry_year.year + 1, 7, 1)

				last_step_request_xml_text, last_step_result_xml_text = single_step_request(loan_year, full_term, lodgement_date, cb, repayments_for_income_year(repayments, enquiry_year), enquiry_year)

				comments.append(last_step_request_xml_text)
				comments.append(last_step_result_xml_text)

				print('last_step_result_xml_text:\n' + last_step_result_xml_text)
				step = fromstring(last_step_result_xml_text)

				cb = float(step.find('ClosingBalance').text)

				if float(step.find('RepaymentShortfall').text) != 0:
					break
				if cb == 0:
					break
				if enquiry_year >= 2024:
					break
					
			write_multistep_testcase(loan_year, full_term, lodgement_date, principal, repayments, enquiry_year, last_step_result_xml_text, comments)
	
	

counter = 2000


def write_multistep_testcase(
	income_year_of_loan_creation,
	full_term_of_loan_in_years,
	lodgement_day_of_private_company,
	opening_balance,
	repayment_dicts,
	income_year_of_computation,
	single_step_result_xml_text,
	comments
):

	global counter

	doc = request_xml(
		income_year_of_loan_creation,
		full_term_of_loan_in_years,
		lodgement_day_of_private_company,
		opening_balance,
		repayment_dicts,
		income_year_of_computation
	)

	cases_dir = Path('multistep')

	counter += 1
	id = f'{counter:07d}'

	case_dir = Path(f'{cases_dir}/{id}')
	case_dir.mkdir(parents=True)

	inputs_dir = case_dir / 'request'
	inputs_dir.mkdir(parents=True)

	outputs_dir = case_dir/ 'responses'
	outputs_dir.mkdir(parents=True)

	with open(inputs_dir / 'request.xml', 'w') as f:
		f.write(doc.toprettyxml(indent='\t'))
		f.write('\n\n\n'.join([''] + comments+['']))

	with open(outputs_dir / 'response.xml', 'w') as f:
		f.write(single_step_result_xml_text)



def request_xml(
	income_year_of_loan_creation,
	full_term_of_loan_in_years,
	lodgement_day_of_private_company,
	opening_balance,
	repayment_dicts,
	income_year_of_computation
):
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
		field('Lodgement day of private company', (lodgement_day_of_private_company))
	field('Income year of computation', income_year_of_computation)

	# maybe we could generate some testcases with principal rather than opening balance tag, it will mean the same thing.
	field('Opening balance of computation', opening_balance)
	# field('Principal amount of loan', opening_balance)

	for r in repayment_dicts:
		repayment = repayments.appendChild(doc.createElement('repayment'))
		repayment.setAttribute('date', python_date_to_xml(r['date']))
		repayment.setAttribute('value', str(r['amount']))

	return doc


def repaymentset(start, end_inclusive):
	
	date = start
	repayments = []

	while date <= end_inclusive:
		date += timedelta(days=random.randint(0, 400))
		repayments.append(dict(date=date, amount=random.randint(0, 50000)))
	
	return repayments



if __name__ == '__main__':
	run()


