#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""

Study and training support loans repayment calculator for 2018/19:

reverse engineered from:
https://www.ato.gov.au/Calculators-and-tools/Host/?anchor=STLoanRepay#STLoanRepay/questions
and other materials.


There are 2 uses for tax estimate - a. When exact tax fact values are entered into the form with all relevant tax paper facts. i.e. Resident/Non Resident. b. for estimation & planning purposes. Currently our system is built to handle a.
But goal is to also have. b.

- however, the ATO calculator deals with estimates only, or at least is worded as such. Accordingly, this code is meant to deal with estimates only, even if the word "estimated" is often dropped for brevity.



inputs:
	
	first two questions:
	"Do you anticipate that you will not have to pay the Medicare levy? *" / (or will be eligible for a reduction?)
	"Were you an Australian resident for the full income year? *"
	
	- if both answers are yes, no additional inputs are required, and the repayment estimate is $0.
	- of any is no, then all the other input fields are shown, except that "Estimated net foreign income while you were a non-resident " is only shown if "Australian resident for the full income year?" is false.
	
	then the unchanging main inputs section:
	
		Estimated net foreign income while you were a non-resident (if not hidden) (converted into Australian currency (https://www.ato.gov.au/Calculators-and-tools/Foreign-income-conversion-calculator/ ))
		Estimated Australian taxable income for the income year (disregarding assessable First Home Super Saver Scheme (FHSS) released amount)

		optional, additional income or losses, default to 0:
			Estimated reportable fringe benefits amounts
			Estimated net investment losses (including net rental losses)
			Estimated reportable super contributions
			Estimated exempt foreign income while an Australian resident
		
		Amount of current debt at 1 June immediately before the making of your assessment:
			HELP
			SFSS
			SSL
			ABSTUDY
			TSL
			

calculations:
	Estimated Australian repayment income = sum (
		Estimated Australian taxable income for the income year 
		Reportable fringe benefit amounts
		Net investment losses
		Reportable super contributions
		Exempt foreign income while an Australian resident
	)

	Estimated worldwide repayment income =
		Estimated Australian repayment income +
		Estimated net foreign income while you were a non-resident 

	the following pseudocode for the main calculations, as i understood them from the calculator website and other pages, isn't quite right, because they reference each other in an apparently endless cycle. In the implementation below, i have experimentally resolved this by splitting up the concept of an estimated repayment into a "maximal", theoretic value, and "clipped" value, which takes into account that the actual rest of the debt can be lower than the "maximal" value. So far it seems i got this right.

	Compulsory repayment estimate for loan type =
		min
		(
			(repayment rate(loan_type, Estimated Australian repayment income) * 	Estimated Australian repayment income),
			current debt - Overseas levy estimate
		)

	Overseas levy estimate for loan type =
		for HELP, TLS:
			min (
				(repayment rate(loan_type, Estimated worldwide repayment income) * 	Estimated worldwide repayment income) - Compulsory repayment estimate,
				current debt
			)
		otherwise 0

	if "Do you anticipate that you will not have to pay the Medicare levy? *" was answered yes, then compulsory repayment will always be $0.

"""

from math import floor

def repayment_rate(loan_type, income):
	"""
		repayment rate(loan_type, income) =
		if income < $51,957: 0
		otherwise:
			SFSS:
				$51,957 – $64,306: 2%
				$64,307 – $91,425: 3%
				$91,426 and above: 4%
			the others:
				$51,957 – $57,729: 2.0%
				$57,730 – $64,306:	4.0%
				$64,307 – $70,881: 	4.5%
				$70,882 – $74,607: 	5.0%
				$74,608 – $80,197: 	5.5%
				$80,198 – $86,855: 	6.0%
				$86,856 – $91,425: 	6.5%
				$91,426 – $100,613: 7.0%
				$100,614 – $107,213: 	7.5%
				$107,214 and above: 8.0%
	"""
	if income < 51957: return 0
	else:
		if loan_type == 'SFSS':
			if income <= 64306: return 0.02
			if income <= 91425: return 0.03
			else: return 0.04
		else:
			if income <= 57729: return 0.02
			if income <= 64306: return 0.04
			if income <= 70881: return 0.045
			if income <= 74607: return 0.05
			if income <= 80197: return 0.055
			if income <= 86855: return 0.06
			if income <= 91425: return 0.065
			if income <= 100613: return 0.07
			if income <= 107213: return 0.075
			return 0.08
	
def compulsory_maximal(loan_type, australian_income):
	"""theoretical compulsory repayment amount"""
	return repayment_rate(loan_type, australian_income) * australian_income
	
def levy_maximal(loan_type, worldwide_repayment_income, compulsory_repayment):
	"""theoretical overseas levy amount"""
	if loan_type in ['HELP', 'TSL']:
		return (repayment_rate(loan_type, worldwide_repayment_income) * worldwide_repayment_income) - compulsory_repayment
	else: return 0	
	
def compulsory_clipped(debt_amount, levy_clipped, compulsory_maximal):
	"""compulsory repaiment taking into account current debt"""
	return min (
		compulsory_maximal,
		debt_amount - levy_clipped
	)

def levy_clipped(debt_amount, levy_maximal):
	"""overseas levy taking into account current debt"""
	return min (
		levy_maximal,
		debt_amount
	)

def repayments_clipped(debt_amount, max_compulsory, max_levy):
	lc = levy_clipped(debt_amount, max_levy)
	cc = compulsory_clipped(debt_amount, lc, max_compulsory)
	#print(cc, lc)
	return cc, lc

def repayment_maximums(loan_type, australian_income, worldwide_income, medicare_exemption):
	"""
	If "Do you anticipate that you will not have to pay the Medicare levy? *" (medicare exemption) was answered yes, then australian income is, for purposes of compulsory repayment estimate, taken to be $0, (and so compulsory repayment estimate will be $0), but it still contributes to worldwide income for purposes of levy estimate.
	"""
	if medicare_exemption:
		max_compulsory = 0
	else:
		max_compulsory = compulsory_maximal(loan_type,australian_income)
	max_levy = levy_maximal(loan_type, worldwide_income, max_compulsory)
	return max_compulsory, max_levy

for testcase in (
	[{'HELP': 10500},100000,180000, 0, 10500],
	[{'HELP': 30500},100000,180000, 7000, 15400],
	[{'HELP': 305000},100000, 180000, 7000, 15400],
	[{'HELP': 305000},100000, 0, 7000, 0],
	[{'HELP': 5000},1000000, 2000000, 0, 5000],
	[{'HELP': 45000},1000000, 2000000, 0, 45000],
	[{'HELP': 450000},1000000, 2000000, 80000, 160000],
	[{'HELP': 30500}, 202,10, 0, 0],
	[{'HELP': 30500}, 202000,10, 16160, 0],
	[{'HELP': 500}, 202000,10, 499, 0],
	[{'HELP': 500}, 202020,60606, 0, 500],

	[{'HELP': 10500, 'TSL': 3213,'SFSS':17},100000,180000, 17, 13713],
	[{'HELP': 10500, 'TSL': 3213,'SFSS':17, 'medicare_exemption':True},100000,180000, 0, 13713],
	[{'HELP': 10500, 'TSL': 3213,'SFSS':17000},100000,180000, 4000, 13713],
	[{'HELP': 10500, 'TSL': 3213,'SFSS':17000, 'medicare_exemption':True},100000,180000, 0, 13713],
	[{'ABSTUDY': 30500, 'TSL': 54654},100000,180000, 7000, 15400],
	[{'ABSTUDY': 30500},100000,180000, 7000, 0],
	[{'SFSS': 305000},100000, 180000, 4000, 0],
	[{'SFSS': 305000, 'medicare_exemption':True},100000, 180000, 0, 0],
	[{'SSL': 5000, 'medicare_exemption':True},1000000, 2000000, 0, 0],
	[{'SSL': 5000},1000000, 2000000, 5000, 0],
	[{'SSL': 500000},1000000, 2000000, 80000, 0],
	[{'HELP': 305000, 'ABSTUDY':6857654},100000, 0, 7000, 0],
	[{'HELP': 305000, 'ABSTUDY':6857654},100000, 654654, 7000, 53372],
	[{'SSL': 45000, 'SFSS': 0},1000000, 2000000, 45000, 0],
	[{'HELP': 450000, 'SSL': 45000, 'SFSS': 0},1000000, 2000000, 80000, 160000],
	[{'HELP': 450000, 'SSL': 45000, 'SFSS': 0, 'medicare_exemption':True},1000000, 2000000, 0, 240000],
	[{'HELP': 450000, 'ABSTUDY':12},1000000, 2000000, 80000, 160000],
	[{'HELP': 30500, 'TSL': 687}, 202,10, 0, 0],
	[{'SFSS': 130500, 'TSL': 687}, 202000,10, 8766, 0],
	[{'SFSS': 130500, 'TSL': 687, 'medicare_exemption':True}, 202000,10, 0, 687],
	):
	print(testcase)
	
	(options, 
	# this is the Estimated Australian repayment income defined in above in "calculations":
	australian_income, 
	# Estimated net foreign income while you were a non-resident:
	foreign_income, 
	# the totals as produced by the calculator:
	expected_compulsory, expected_levy) = testcase
	
	try:
		medicare_exemption = options['medicare_exemption']
	except KeyError:
		medicare_exemption = False
	
	worldwide_income = australian_income + foreign_income
	
	total_compulsory_repayment_estimate = 0
	total_overseas_levy_estimate = 0
	
	#all the loan types in the group have the same repayment rate, and even if you have more loans from same group, you will only pay up to the maximum amount for that group. In other words, ABSTUDY and TSL compulsory repayment amounts will only add up to an amount computed from the rates table, not more.
	for loan_type_group in [['SFSS'], ['HELP', 'SSL', 'ABSTUDY', 'TSL']]:
		
		#just use the first one in the group to look up the group max
		max_group_compulsory, max_group_levy = repayment_maximums(loan_type_group[0], australian_income, worldwide_income, medicare_exemption)
		
		group_compulsory_repayment_estimate = 0
		group_overseas_levy_estimate = 0
	
		for loan_type in loan_type_group:
			if loan_type in options:

				debt_amount = options[loan_type]


				#Debt types within a group have different rules wrt overseas levy, so now we get the theoretic maximum for the exact loan type
				max_compulsory, max_levy = repayment_maximums(loan_type, australian_income,
 worldwide_income, medicare_exemption)
				#clipped by current debt:
				compulsory_repayment, overseas_levy = repayments_clipped(debt_amount, max_compulsory, max_levy)
				
				#pay at most the total group amount
				to_repay = min(compulsory_repayment, max_group_compulsory - group_compulsory_repayment_estimate)
				if to_repay > 0:
					group_compulsory_repayment_estimate += to_repay
					print (loan_type + ': compulsory: $' + str(to_repay))	
				to_repay = min(overseas_levy, max_group_levy - group_overseas_levy_estimate)
				if to_repay > 0:
					group_overseas_levy_estimate += to_repay
					print (loan_type + ': levy: $' + str(to_repay))	

		total_compulsory_repayment_estimate += group_compulsory_repayment_estimate
		total_overseas_levy_estimate += group_overseas_levy_estimate


	print ('total compulsory: $'+str(total_compulsory_repayment_estimate) + ' total levy: $'+str( total_overseas_levy_estimate))
	print ('total: $'+str(total_compulsory_repayment_estimate+total_overseas_levy_estimate))
	print ()
	try:
		assert expected_compulsory == floor(total_compulsory_repayment_estimate)
		assert expected_levy == floor(total_overseas_levy_estimate)
	except AssertionError as e:
		print("fffffffffffffffffffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaiiiiiiiiiiiiiiiiiiiiiiiiiiiilllllllllllllllllllllllllllll")
		raise e

	


"""
random notes:

1 June 2018


source: 

https://www.ato.gov.au/Rates/HELP,-TSL-and-SFSS-repayment-thresholds-and-rates

2018–19 repayment income thresholds and rates for HELP, SSL, ABSTUDY SSL and TSL

Repayment income (RI*), Repayment rate


*RI= Taxable income plus any total net investment loss (which includes net rental losses), total reportable fringe benefits amounts, reportable super contributions and exempt foreign employment income.


I am ignoring the option to calculate for a different year than 2018/19.


100, 101, 101, "Do you anticipate that you will not have to pay the Medicare levy?"
101, 200, get_non_resident_foreign_income, Were you an Australian resident for the full income year?

200, 1000 :-
	answered(100, 1)
	
result_state(1000, 0) :-
	answered(100, 1),
	answered(200, 1).

get_non_resident_foreign_income, do_you_know_your_non_resident_foreign_income :-
	non_resident_foreign_income unknown

get_non_resident_foreign_income, do_you_know_your_non_resident_foreign_income :-
	non_resident_foreign_income unknown


"""
