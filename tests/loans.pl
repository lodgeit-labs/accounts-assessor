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
		loan_agr_min_yearly_repayment(loan_agreement(0, 75000, Lodgement_Day, Begin_Day, 7, 0, false,
			[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), 0, Min_Yearly_Repayment)),
		
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
		loan_agr_total_interest(loan_agreement(0, 75000, Lodgement_Day, Begin_Day, 7, 0, false,
			[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), 0, Total_Interest)),
		
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
		loan_agr_total_repayment(loan_agreement(0, 75000, Lodgement_Day, Begin_Day, 7, 0, false,
			[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), 0, Total_Repayment)),
		
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
		loan_agr_total_principal(loan_agreement(0, 75000, Lodgement_Day, Begin_Day, 7, 0, false,
			[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), 0, Total_Principal)),
		
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
		loan_agr_summary(loan_agreement(0, 75000, Lodgement_Day, Begin_Day, 7, 0, false,
			[loan_repayment(Payment1_Day, 20000), loan_repayment(Payment2_Day, 8000)]), Summary)),
	
	[loan_summary(0, 55000, 5.95, 9834.923730309263, 28000, 0, 3230.7684931506847, 24769.231506849315, 50230.76849315068)]).

% Summarize the information pertaining to the income years after a loan agreement is
% made. The relevant information is that the first income year begins on date(2016, 7, 1).
% The private company's lodgement day is date(2017, 5, 15). A payment of $3,000 is made
% on date(2017, 7, 1). The income year of computation is 2018 and it opens with a balance
% of $10,000. The loan has a term of 4 years.

write("Is output for the loan summary information of a different agreement correct?"),

findall(Summary,
	(absolute_day(date(2016, 7, 1), Begin_Day),
		absolute_day(date(2017, 5, 15), Lodgement_Day),
		absolute_day(date(2017, 7, 1), Payment1_Day),
		loan_agr_summary(loan_agreement(0, 75000, Lodgement_Day, Begin_Day, 4, 1, 10000,
			[loan_repayment(Payment1_Day, 3000)]), Summary)),
	
	[loan_summary(1, 10000, 5.3, 3692.746389804068, 3000, 692.7463898040678, 371.0, 2629.0, 7371.0)]).
	
% See the loan summary schema in loans.pl .

