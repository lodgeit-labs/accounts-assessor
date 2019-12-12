:- use_module(library(clpq)).

help(test) :-
	writeln("test(HP_Begin_Date, HP_Payment_Type, HP_Cash_Price, Opening_Balance, Interest_Rate, Repayment_Period, Interest_Period, Interest_Amount, Repayment_Amount, Closing_Balance, Opening_Date, Closing_Date, Installment_Number)").
help(test2) :-
	writeln("test2(HP_Begin_Date, HP_Payment_Type, HP_Cash_Price, HP_Duration, HP_Repayment_Period, HP_Repayment_Amount, HP_Interest_Period, HP_Interest_Rate, HP_Installments, HP_Number_of_Installments, HP_End_Date, HP_Total_Interest, HP_Total_Payments)"). 

% can infer any single missing variable
% in certain cases it can infer two missing variables
test(
	HP_Begin_Date,				% currently integer-valued; lacking date/time dimensional stuff
	HP_Payment_Type,			% 0 = advance; 1 = arrears
	Opening_Balance,			% currently lacking currency units
	Interest_Rate,				% %-interest per Interest_Period; lacking currency and date/time dimensional stuff
	Repayment_Period,  			% currently integer-valued; lacking date/time dimensional stuff; 
								% Period over which repayments happen; not necessarily equal to Interest_Period
	Interest_Period,			% currently integer-valued; lacking 
	Interest_Amount,			% currently lacking currency units
	Repayment_Amount,			% currently lacking currency units
	Closing_Balance,			% currently lacking currency units
	Opening_Date,				% currently integer-valued; lacking date/time dimensional stuff
	Closing_Date,				% currently integer-valued; lacking date/time dimensional stuff
	Installment_Number 			% 0-indexed
) :-
	% HP_Payment_Type: 0 = advance ; 1 = arrears
	{ Opening_Date = HP_Begin_Date + (HP_Payment_Type * Repayment_Period) + (Installment_Number * Repayment_Period)}, 

	% note: need proper date/time units handling here
	% main thing is month-duration irregularity
	{ Repayment_Period = Closing_Date - Opening_Date },

	% note: need proper date/time units handling here
	{ Period = (Repayment_Period / Interest_Period ) },

	% note: there are other ways to calculate interest
	{ Opening_Balance * Interest_Rate * Period = Interest_Amount },

	{ Opening_Balance + Interest_Amount - Repayment_Amount = Closing_Balance}.





test2(
	HP_Begin_Date,				% currently integer-valued; lacking date/time dimensional stuff
	HP_Payment_Type,			% 0 = advance; 1 = arrears
	HP_Cash_Price,
	HP_Duration,
	HP_Repayment_Period,
	HP_Repayment_Amount,
	HP_Interest_Period,
	HP_Interest_Rate,
	HP_Installments,
	HP_Number_Of_Installments,
	HP_End_Date,
	HP_Total_Interest,
	HP_Total_Payments
) :-
	HP_Number_Of_Installments > 0,
	HP_Installments = [ installment(1, Opening_Date, Opening_Balance, _, _, _) | _],
	{HP_Cash_Price = Opening_Balance },
	{ Opening_Date = HP_Begin_Date + (HP_Payment_Type * HP_Repayment_Period)}, 
	{HP_Period = HP_Repayment_Period / HP_Interest_Period},
	{ Dummy_Closing_Date = Opening_Date - 1},
	gen_hp_installments(HP_Interest_Rate, HP_Period, HP_Repayment_Period, HP_Repayment_Amount, HP_Number_Of_Installments, 0, HP_Cash_Price, Dummy_Closing_Date, HP_Installments),

	installments_payments(HP_Installments, HP_Total_Payments),
	installments_interest(HP_Installments, HP_Total_Interest),
	installments_last_closing_date(HP_Installments, HP_End_Date),
	% evaluates false due to rounding errors
	%{HP_Total_Payments = HP_Cash_Price + HP_Total_Interest}
	{HP_End_Date = HP_Begin_Date + HP_Duration}.

gen_hp_installments(
	HP_Interest_Rate,
	HP_Period,
	HP_Repayment_Period,
	HP_Repayment_Amount,
	HP_Number_Of_Installments,
	Previous_Installment_Number,
	Previous_Closing_Balance,
	Previous_Closing_Date,
	[installment(Installment_Number, Opening_Date, Opening_Balance, Interest_Amount, Closing_Date, Closing_Balance)  | Installments]
) :-
	{Opening_Balance = Previous_Closing_Balance},
	{Opening_Date = Previous_Closing_Date + 1},
	{Closing_Date = Opening_Date + HP_Repayment_Period - 1},
	{Installment_Number = Previous_Installment_Number + 1},
	{Interest_Amount = Opening_Balance * HP_Interest_Rate * HP_Period},
	{Closing_Balance = Opening_Balance + Interest_Amount - HP_Repayment_Amount},
	(
		Installment_Number < HP_Number_Of_Installments
	->
		gen_hp_installments(HP_Interest_Rate, HP_Period, HP_Repayment_Period, HP_Repayment_Amount, HP_Number_Of_Installments, Installment_Number, Closing_Balance, Closing_Date, Installments)
	;
		Installments = []
	).

installments_interest([], 0).
installments_interest([installment(_,_,_,Interest_Amount,_,_) | Rest], Total_Interest) :-
	installments_interest(Rest, Rest_Interest),
	{Total_Interest = Rest_Interest + Interest_Amount}.

installments_payments([], 0).
installments_payments([installment(_,_,Opening_Balance,Interest_Amount,_,Closing_Balance) | Rest], Total_Payments) :-
	installments_payments(Rest, Rest_Payments),
	{Closing_Balance = Opening_Balance + Interest_Amount - Current_Payment},
	{Total_Payments = Rest_Payments + Current_Payment}.

installments_last_closing_date([installment(_,_,_,_,End_Date,_)], End_Date).
installments_last_closing_date([_ | [ Installment | Rest ]], End_Date) :-
	installments_last_closing_date([Installment | Rest], End_Date).

write_installments([]).
write_installments([installment(Installment_Number, Opening_Date, Opening_Balance, Interest_Amount, Closing_Date, Closing_Balance) | Rest]) :-
	Rounded_Opening_Balance is float(Opening_Balance),
	Rounded_Interest_Amount is float(Interest_Amount),
	Rounded_Closing_Balance is float(Closing_Balance),
	format("~w, ~w - ~w: ~w, ~w, ~w~n", [Installment_Number, Opening_Date, Closing_Date, Rounded_Opening_Balance, Rounded_Interest_Amount, Rounded_Closing_Balance]),
	write_installments(Rest).

% now needs to handle all the installments...
% relate Number_Of_Installments to the count of the installments
% relate first installment to opening balance
% relate installment to next and previous installments
% relate current Closing_Balance to next Opening_Balance
% assert that the installments in the sequence are the only ones
% detect balloon payments
% if-then-else with CLP when the conditions might be variable ?
% handling units with CLP?
% handling date/time stuff with CLP?
% numeric stuff; limited-precision arithmetic relations; rounding
% proof-tracing
