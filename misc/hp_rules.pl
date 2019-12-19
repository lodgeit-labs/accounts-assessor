implication(
	[
		concept_data(HP, paymentType, arrears),
		concept_data(HP, beginDate, Begin_Date)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		\+concept_data(Installment, prev, _),
		concept_data(Installment, date, Date),
		concept_data(Installment, duration, Duration),
		date_add(Begin_Date, Duration, Date)
	]
).

implication(
	[
		concept_data(Installment, date, Date)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, paymentType, arrears),
		concept_data(HP, beginDate, Begin_Date)
		\+concept_data(Installment, prev, _),
		concept_data(Installment, duration, Duration),
		add_date_duration(Begin_Date, Duration, Date)
	]
).

implication(
	[
		concept_data(HP, paymentType, advance),
		concept_data(HP, beginDate, Begin_Date)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		\+concept_data(Installment, prev, _),
		concept_data(Installment, date, Begin_Date)
	]
).

implication(
	[
		concept_data(Installment, date, Date)
	]
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, paymentType, advance),
		concept_data(HP, beginDate, Date),
		concept_data(HP, installment, Installment),
		\+concept_data(Installment, prev, _)
	]
).

implication(
	[
		concept_data(Installment, date, Date)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(Installment, prev, Prev),
		concept_data(Prev, date, Prev_Date),
		concept_data(Prev, duration, Duration),
		add_date_duration(Prev_Date, Duration, Date)
	]
).

implication(
	[
		concept_data(Installment, openingDate, Opening_Date)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(Installment, next, Next),
		concept_data(Next, date, Next_Date),
		concept_data(Installment, duration, Duration),
		add_date_duration(Date, Duration, Next_Date)
	]
).

implication(
	[
		concept_data(Installment, closingDate, Closing_Date)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		...
	]
).

implication(
	[
		concept_data(Installment, opening_balance, Opening_Balance)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		\+(concept_data(Installment, prev, _),
		concept_data(HP, cashPrice, Opening_Balance)
	]
).

implication(
	[
		concept_data(Installment, opening_balance, Opening_Balance)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(Installment, prev, Prev_Installment),
		concept_data(Prev_Installment, closing_balance, Opening_Balance)
	]
).

implication(
	[
		concept_data(Installment, interestRate, Interest_Rate)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(HP, interestRate, Interest_Rate)
	]
).

implication(
	[
		concept_data(Installment, interestAmount, Interest_Amount)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(HP, interestPeriod, Interest_Period),
		concept_data(Installment, interestRate, Interest_Rate),
		concept_data(Installment, openingBalance, Opening_Balance),
		concept_data(Installment, duration, Duration),
		Interest_Amount is Opening_Balance * Interest_Rate * (Duration / Interest_Period)
	]
).

implication(
	[
		concept_data(Installment, repaymentAmount, Repayment_Amount)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, repaymentAmount, Repayment_Amount),
		concept_data(HP, installment, Installment)
	]
).

implication(
	[
		concept_data(HP, repaymentAmount, Repayment_Amount)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(Installment, repaymentAmount, Repayment_Amount)
	]
).

implication(
	[
		concept_data(HP, repaymentAmount, Repayment_Amount)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, interestRate, Interest_Rate),
		concept_data(HP, numberOfInstallments, Number_Of_Installments),
		concept_data(HP, cashPrice, Cash_Price)
		concept_data(HP, interestPeriod, Interest_Period),
		concept_data(HP, repaymentPeriod, Repayment_Period),
		...
	]
).

% needs existentials?
implication(
	[
		concept_data(HP, installment, Installment),
		concept_data(Installment, installmentNumber, Installment_Number)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, numberOfInstallments, Number_Of_Installments),
		range(1,Number_Of_Installments,1,Installment_Number),
		fresh_bnode(Installment)
	]
).

implication(
	[
		concept_data(Installment, duration, Duration)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(HP, period, Duration)
	]
).

implication(
	[
		concept_data(Installment, duration, Duration)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(Installment, opening_date, Opening_Date),
		concept_data(Installment, closing_date, Closing_Date),
		date_add(Closing_Date, 1 day, Next_Opening_Date),
		date_add(Opening_Date, Duration, Next_Opening_Date)
	]
).

implication(
	[
		concept_data(Installment, next, Next_Installment)
	],
	[
		concept_data(Next_Installment, prev, Installment)
	]
).

implication(
	[
		concept_data(Installment, prev, Prev_Installment)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(Prev_Installment, next, Installment)
	]
).

implication(
	[
		concept_data(Installment, installmentNumber, 0)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		\+(concept_data(Installment, prev, _)
	]
).

implication(
	[
		concept_data(Installment, installmentNumber, SX)
	],
	[
		concept_data(HP, 'a', hp_arrangement),
		concept_data(HP, installment, Installment),
		concept_data(Installment, prev, Prev_Installment),
		concept_data(Prev_Installment, installmentNumber, X),
		SX is X + 1
	]
).