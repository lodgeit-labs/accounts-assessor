write("Are we now testing the loan calculator subprogram?").

% The following examples are based on examples 6, 7, 8, and, 9 of
% https://www.ato.gov.au/business/private-company-benefits---division-7a-dividends/in-detail/division-7a---loans/

% What is the minimum yearly repayment of the first income year after a loan agreement
% is made? The relevant information is that the first income year begins on
% date(2014, 7, 1). The private company's lodgement day is date(2015, 5, 15). A payment
% of $20,000 is made on date(2014, 8, 31). A payment of $8,000 is made on
% date(2015, 5, 30). The principal amount of the loan is $75,000. The loan has a term of
% 7 years.

write("Is output for the minimum yearly repayment for the first income year correct?"),

findall(Min_Yearly_Repayment,
	(absolute_day(date(2014, 7, 1), Begin_Day),
		absolute_day(date(2014, 8, 31), Payment1_Day),
		absolute_day(date(2015, 5, 15), Lodgement_Day),
		absolute_day(date(2015, 5, 30), Payment2_Day),
		loan_agr_prepare(loan_agreement(0, 75000, 0, Lodgement_Day, Begin_Day, 7, 0, false,
		[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), Prepared_Agreement),
		loan_agr_min_yearly_repayment(Prepared_Agreement, 0, Min_Yearly_Repayment)),
		
	[9834.923730309263]).

% What is the total interest owed in the first income year after a loan agreement
% is made? The relevant information is that the first income year begins on
% date(2014, 7, 1). The private company's lodgement day is date(2015, 5, 15). A payment
% of $20,000 is made on date(2014, 8, 31). A payment of $8,000 is made on
% date(2015, 5, 30). The principal amount of the loan is $75,000. The loan has a term of
% 7 years.

write("Is output for the total interest received in the first year correct?"),

findall(Total_Interest,
	(absolute_day(date(2014, 7, 1), Begin_Day),
		absolute_day(date(2014, 8, 31), Payment1_Day),
		absolute_day(date(2015, 5, 15), Lodgement_Day),
		absolute_day(date(2015, 5, 30), Payment2_Day),
		loan_agr_prepare(loan_agreement(0, 75000, 0, Lodgement_Day, Begin_Day, 7, 0, false,
		[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), Prepared_Agreement),
		loan_agr_total_interest(Prepared_Agreement, 0, Total_Interest)),
		
	[3230.7684931506847]).

% What is the total amount paid in the first income year after a loan agreement is made?
% The relevant information is that the first income year begins on date(2014, 7, 1). The
% private company's lodgement day is date(2015, 5, 15). A payment of $20,000 is made on
% date(2014, 8, 31). A payment of $8,000 is made on date(2015, 5, 30). The principal
% amount of the loan is $75,000. The loan has a term of 7 years.

write("Is output for the total repayment in the first income year correct?"),

findall(Total_Repayment,
	(absolute_day(date(2014, 7, 1), Begin_Day),
		absolute_day(date(2014, 8, 31), Payment1_Day),
		absolute_day(date(2015, 5, 15), Lodgement_Day),
		absolute_day(date(2015, 5, 30), Payment2_Day),
		loan_agr_prepare(loan_agreement(0, 75000, 0, Lodgement_Day, Begin_Day, 7, 0, false,
		[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), Prepared_Agreement),
		loan_agr_total_repayment(Prepared_Agreement, 0, Total_Repayment)),
		
	[28000]).

% What is the principal amount paid in the first income year after a loan agreement is
% made? The relevant information is that the first income year begins on date(2014, 7, 1).
% The private company's lodgement day is date(2015, 5, 15). A payment of $20,000 is made
% on date(2014, 8, 31). A payment of $8,000 is made on date(2015, 5, 30). The principal
% amount of the loan is $75,000. The loan has a term of 7 years.

write("Is output for the principal amount paid in the first year correct?"),

findall(Total_Principal,
	(absolute_day(date(2014, 7, 1), Begin_Day),
		absolute_day(date(2014, 8, 31), Payment1_Day),
		absolute_day(date(2015, 5, 15), Lodgement_Day),
		absolute_day(date(2015, 5, 30), Payment2_Day),
		loan_agr_prepare(loan_agreement(0, 75000, 0, Lodgement_Day, Begin_Day, 7, 0, false,
		[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), Prepared_Agreement),
		loan_agr_total_principal(Prepared_Agreement, 0, Total_Principal)),
		
	[24769.231506849315]).

% Summarize the information pertaining to the income years after a loan agreement is
% made. The relevant information is that the first income year begins on date(2014, 7, 1).
% The private company's lodgement day is date(2015, 5, 15). A payment of $20,000 is made
% on date(2014, 8, 31). A payment of $8,000 is made on date(2015, 5, 30). The principal
% amount of the loan is $75,000. The loan has a term of 7 years.

write("Is output for the loan summary information correct?"),

findall(Summary,
	(absolute_day(date(2014, 7, 1), Begin_Day),
		absolute_day(date(2014, 8, 31), Payment1_Day),
		absolute_day(date(2015, 5, 15), Lodgement_Day),
		absolute_day(date(2015, 5, 30), Payment2_Day),
		loan_agr_prepare(loan_agreement(0, 75000, 0, Lodgement_Day, Begin_Day, 7, 0, false,
		[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), Prepared_Agreement),
		loan_agr_summary(Prepared_Agreement, Summary)),
	
	[loan_summary(0, 55000, 5.95, 9834.923730309263, 28000, 0, 3230.7684931506847, 24769.231506849315, 50230.76849315068)]).
	
% See the loan summary schema in loans.pl .

