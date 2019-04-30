"""

Study and training support loans repayment calculator for 2018/19:

inputs:
	
	first two questions:
	"Do you anticipate that you will not have to pay the Medicare levy? *" / (or will be eligible for a reduction?)
	"Were you an Australian resident for the full income year? *"
	
	- if both answers are yes, no additional inputs are required
	- of any is no, then all the other input fields are shown (except that "Estimated net foreign income while you were a non-resident " is only shown if "Australian resident for the full income year?" is false.)
	
	so then we have the unchanging main inputs section:
	
		Estimated net foreign income while you were a non-resident (if not hidden) (converted into Australian currency)
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

from math import floor

def repayment_rate(loan_type, income):
	if income < 51957: return 0
	else:
		if loan_type == 'SFSS':
			if income <= 64306: return 0.02
			if income <= 91425: return 0.03
			else: return 0.04
		else:
			if income <= 57729: return 0.02
			if income <= 64306:	return 0.04
			if income <= 70881: 	return 0.045
			if income <= 74607: 	return 0.05
			if income <= 80197: 	return 0.055
			if income <= 86855: 	return 0.06
			if income <= 91425: 	return 0.065
			if income <= 100613: return 0.07
			if income <= 107213: 	return 0.075
			return 0.08
				

#def total_overseas_levy():
#	...
			

def compulsory_maximal(loan_type, debt, australian_income):
	return repayment_rate(loan_type, australian_income) * australian_income
	
def compulsory_clipped(loan_type, debt, australian_income, levy_clipped):
	return min (
		compulsory_maximal(loan_type, debt, australian_income),
		debt - levy_clipped
	)
			
def levy_maximal(loan_type, debt, worldwide_repayment_income, compulsory_repayment):
		if loan_type in ['HELP', 'TLS']:
			return (repayment_rate(loan_type, worldwide_repayment_income) * 	worldwide_repayment_income) - compulsory_repayment
		else: return 0	
			
def levy_clipped(loan_type, debt, worldwide_repayment_income, compulsory_repayment):
	return min (
		levy_maximal(loan_type, debt, worldwide_repayment_income, compulsory_repayment),
		debt
	)

for testcase in (
	['HELP', 10500,100000,180000, 0, 10500],
	['HELP', 30500,100000,180000, 7000, 15400],
	['HELP', 305000,100000, 180000, 7000, 15400],
	['HELP', 305000,100000, 0, 7000, 0],
	['HELP', 5000,1000000, 2000000, 0, 5000],
	['HELP', 45000,1000000, 2000000, 0, 45000],
	['HELP', 450000,1000000, 2000000, 80000, 160000],
	['HELP', 30500, 202,10, 0, 0],
	['HELP', 30500, 202000,10, 16160, 0],
	['HELP', 500, 202000,10, 499, 0],
	):
	t,d,australian_income,foreign_income, compulsory, levy = testcase
	print(testcase)
	worldwide_income = australian_income + foreign_income
	cm = compulsory_maximal(t, d, australian_income)
	lm = levy_maximal(t, d, worldwide_income, cm)
	lc = levy_clipped(t, d, worldwide_income, cm)
	cc = compulsory_clipped(t, d, australian_income, lc)
	print(cm, cc)
	print(lm, lc)
	assert compulsory == floor(cc)
	assert levy == floor(lc)
	print()
				
				
				
				
				
				
"""
notes:

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
