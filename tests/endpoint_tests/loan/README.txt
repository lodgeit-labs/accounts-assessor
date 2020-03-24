loan10a,loan10b:
these show the difference that lodgement date makes. 
It should not affect the interest rate, 
but it should affect the minimum yearly repayment.
in 10a, the repayment is before lodgement, and minimum yearly repayment is met. 
	This computes correctly like ATO.
in 10b, the repayment is after lodgement, and minimum yearly repayment is not met. 
	This computes correctly like ATO if loan_reps_before_lodgement is called with Lodgement_Day.
	but if loan_reps_before_lodgement is called with Begin_Day, we compute min repayment incorrectly.
	



loan-1:
	this shows that interest rate is calculated incorrectly (compared to ATO), if loan_reps_before_lodgement is called with Lodgement_Day.





loan-2:
	...




so, at the very least, we have to change the code to use Lodgement_Day.to computed min yearly repayment but Begin_Day to compute interest.

testcases need to be checked and updated once again. 
It's worth it putting ATO results into the request xmls.
