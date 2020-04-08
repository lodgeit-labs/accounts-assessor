chr_fields(hp_arrangement, [
	_{
		key:begin_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:end_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:cash_price,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:normal_interest_rate,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:normal_payment_amount,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:number_of_installments,
		type:integer,
		unique:true,
		required:true
	},
	_{
		key:final_balance,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:installments,
		type:list(hp_installment),
		unique:true,
		required:true
	}
]).


chr_fields(hp_installment, [
	/*
	_{
		key:hp_arrangement,
		type:hp_arrangement,
		unique:true,
		required:true
	},
	*/
	_{
		key:number,
		type:integer,
		unique:true,
		required:true
	},
	_{
		key:opening_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:opening_balance,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:payment_amount,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:interest_rate,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:interest_amount,
		type:rational,
		unique:true,
		required:true
	},
	_{
		key:closing_date,
		type:date,
		unique:true,
		required:true
	},
	_{
		key:closing_balance,
		type:rational,
		unique:true,
		required:true
	}
]).


% HP ARRANGEMENTS & HP INSTALLMENTS THEORY

% HP ARRANGEMENT GLOBAL CONSTRAINTS
fact(HP, a, hp_arrangement)
\
rule
<=>
\+find_fact(rule1, fired_on, [HP])
|
debug(chr_hp_arrangement, "CHR: HP arrangement global constraints rule; HP=~w...~n", [HP]),
fact(rule1, fired_on, [HP]),
add_constraints([

	% relate HP parameters to first and last installments
	% Note that all of these HP parameters are redundant and just referencing values at the endpoints of the HP installments "curve"
	% this assumes that an installment necessarily exists.
	First_Installment 			= HP:installments:first:value,
	HP:cash_price 				= First_Installment:opening_balance,
	HP:begin_date				= First_Installment:opening_date, /* needs payment type parameter */

	Last_Installment 			= HP:installments:last:value,
	HP:final_balance 			= Last_Installment:closing_balance,
	HP:end_date 				= Last_Installment:closing_date,
	HP:number_of_installments 	= Last_Installment:number,

	% special formula: repayment amount
	% the formula doesn't account for balloons/submarines and other variations
	% these are just giving abbreviated variables to use in the special formula:
	P0 = HP:cash_price,    			% P0 = principal / balance at t = 0
	PN = HP:final_balance, 			% PN = principal / balance at t = N
	IR = HP:normal_interest_rate,
	R = HP:normal_payment_amount,
	N = HP:number_of_installments,
	{R = (P0 * (1 + (IR/12))^N - PN)*((IR/12)/((1 + (IR/12))^N - 1))}

]),
debug(chr_hp_arrangement, "CHR: HP arrangement global constraints rule; HP=~w... done~n", [HP]),
rule.




/*
Constraint:

_Body_Keep
\
_Body_Lose
<=>
_Guard
|
_Head.




becomes:

_Body_Keep
\
_Body_Lose,
rule
<=>
_Guard,
\+find_fact(
	_Rule_Name,
	fired_on,
	[_Body_Keep + _Body_Lose]
)
|
fact(
	_Rule_Name,
),
_Head,
rule.
*/


fact(HP, a, hp_arrangement),
fact(HP, installments, Installments),
fact(Cell, list_in, Installments),
fact(Cell, value, Installment)
\
rule
<=>
\+find_fact(has_installment_rule, fired_on, [HP, Installment])
|
fact(has_installment_rule, fired_on, [HP, Installment]),
debug(chr_hp_arrangement, "CHR: has_installment_rule: HP=~w, installments=~w, cell=~w, installment=~w:...~n", [HP, Installments, Cell, Installment]),
add_constraints([
	fact(HP, has_installment, Installment),
	fact(Installment, hp_arrangement, HP),
	fact(Installment, list_cell, Cell)
]),
debug(chr_hp_arrangement, "CHR: has_installment_rule: HP=~w, installments=~w, cell=~w, installment=~w:... done~n", [HP, Installments, Cell, Installment]),
rule.




fact(HP, a, hp_arrangement),
fact(HP, installments, Installments),
fact(Cell, list_in, Installments),
fact(Cell, value, Installment),
fact(Cell, next, Next_Cell),
fact(Next_Cell, value, Next_Installment)
\
rule
<=>
\+find_fact(has_next_installment_rule, fired_on, [HP, Installment])
|
fact(has_next_installment_rule, fired_on, [HP, Installment]),
debug(chr_hp_arrangement, "CHR: has_next_installment_rule: HP=~w, installments=~w, cell=~w, installment=~w:...~n", [HP, Installments, Cell, Installment]),
add_constraints([
	fact(Installment, next, Next_Installment),
	fact(Next_Installment, prev, Installment)
]),
debug(chr_hp_arrangement, "CHR: has_next_installment_rule: HP=~w, installments=~w, cell=~w, installment=~w:... done~n", [HP, Installments, Cell, Installment]),
rule.








% CONSTRAINTS ABOUT ANY GIVEN INSTALLMENT:
fact(HP, a, hp_arrangement),
fact(HP, has_installment, Installment),
fact(Installment, list_cell, Installment_Cell) 
\
rule
<=>
\+find_fact(rule2, fired_on, [HP, Installment])
|
fact(rule2, fired_on, [HP, Installment]),
debug(chr_hp_arrangement, "CHR: hp installment properties rule; HP: ~w, Installment: ~w~n", [HP, Installment]), 
add_constraints([

% relate installment parameters to HP parameters
Installment:hp_arrangement		= HP,
Installment:interest_rate 		= HP:normal_interest_rate,
Installment:payment_amount 		= HP:normal_payment_amount,		% needs to account for balloon payments


% relate opening balance, interest rate, interest amount, payment amount, and closing balance
{Installment:interest_amount 	= Installment:opening_balance * Installment:interest_rate},
{Installment:closing_balance 	= Installment:opening_balance + Installment:interest_amount - Installment:payment_amount},

% let the installment object be treated as a list-cell
Installment_Cell:index 			= Installment:number,



/* 
calculating installment period from index
% note adding: must be same units; //12 is converting units of months to units of years,
% with approximation given by rounding down, which is done because the remainder is given
% as a separate quantity

 % taking mod in this context requires correction for 0-offset of month-index, ex.. january = 1,
(year,month) is effectively a kind of compound unit

% offset is inverse of error
% 
*/
Offset 	#= (HP:begin_date:month - 1) + (Installment:number - 1), % month's unit and installment index have +1 0-offset, -1 is 0-error (deviation from 0)
Year 	#= HP:begin_date:year + (Offset // 12),				% note adding: must be same units; //12 is converting units of months to units of years,
Month	#= ((Offset mod 12) + 1), 							% +1 is return to 0-offset of the month's unit


% just assuming that the opening date is the 1st of the month and closing date is last of the month
% Installment:opening_date = date(Year, Month, 1).	% date{year:Year,month:Month,day:1} ?

Installment:opening_date:year = Year,
Installment:opening_date:month = Month,
Installment:opening_date:day = 1,
Installment:closing_date:year = Year,
Installment:closing_date:month = Month,
Installment:closing_date:day = Installment:closing_date:month_length %,
]),

debug(chr_hp_arrangement, "CHR: hp installment properties rule; HP: ~w, Installment: ~w: ... done.~n", [HP, Installment]), 
rule.

% special formula: closing balance to calculate the closing balance directly from the hp parameters.
% NOTE: approximation errors in input can cause it to calculate a non-integer installment index
/*
P0 = HP.cash_price,
I = HP.installment_number
R = HP.repayment_amount
IR = HP.interest_rate
PI = P0*(1 + (IR/12))^I - R*((1 + (IR/12))^I - 1)/(IR/12)
*/


% if closing balance is not equal to the final balance then there should be another installment after it
fact(HP, a, hp_arrangement),
fact(HP, installments, Installments),
fact(Installment_Cell, list_in, Installments),
fact(Installment_Cell, value, Installment),
fact(Installment, opening_balance, Opening_Balance),
fact(Installment, closing_balance, Closing_Balance),
fact(HP, final_balance, Final_Balance)
\
rule
<=>
nonvar(Opening_Balance),
nonvar(Closing_Balance),
nonvar(Final_Balance),
Opening_Balance > Closing_Balance,
Closing_Balance > Final_Balance,
\+find_fact(installment_generating_rule, fired_on, [HP, Installment_Cell])
|
fact(installment_generating_rule, fired_on, [HP, Installment_Cell]),
debug(chr_hp_arrangement, "CHR: installment generating rule: hp=~w, installments=~w, installment=~w~n", [HP, Installments, Installment_Cell]),
add_constraints([
	fact(Installment_Cell, next, _)
]),
rule.











% Constraint relating adjacent installments: continuity principle
% Other constraints are handled by the list theory.
fact(HP, a, hp_arrangement),
fact(HP, has_installment, Installment),
fact(Installment, next, Next_Installment)
\
rule
<=>
\+find_fact(rule3, fired_on, [HP, Installment, Next_Installment])
|
fact(rule3, fired_on, [HP, Installment, Next_Installment]),
debug(chr_hp_arrangement, "CHR: continuity rule: hp=~w, installment=~w, next_installment=~w: ... ~n", [HP, Installment, Next_Installment]),
add_constraints([
	Installment:closing_balance = Next_Installment:opening_balance
]),
debug(chr_hp_arrangement, "CHR: continuity rule: hp=~w, installment=~w, next_installment=~w: ... done.~n", [HP, Installment, Next_Installment]),
rule.








/*
% 
% if the cash price is different from the final balance, there must be an installment
% this is really an instance of a more general principle:
% if installment X precedes installment Y, and X.closing_balance \= Y.opening_balance, there must be an installment in between X and Y
% conversely, if there is no installment between X and Y, then X.closing_balance = Y.opening_balance

rule, fact(HP, a, hp_arrangement), fact(HP, cash_price, Cash_Price), fact(HP, final_balance, Final_Balance), fact(HP, installments, Installments) ==> \+find_fact2(_, list_in, Installments1, [Installments1:Installments]), nonvar(Cash_Price), nonvar(Final_Balance), Cash_Price \== Final_Balance | debug(chr_hp, "if the cash price is different from the final balance, there must be an installment.~n", []), fact(_, list_in, Installments).

% this isn't a logical validity it's just a heuristic meant to generate the list when the parameters are underspecified
% if closing balance is greater than or equal to repayment amount, there should be another installment after it
fact(HP, a, hp_arrangement),
fact(HP, repayment_amount, Repayment_Amount),
fact(HP, installments, Installments),
fact(Installment_Cell, list_in, Installments),
fact(Installment_Cell, value, Installment),
fact(Installment, closing_balance, Closing_Balance)
\
rule
<=> 

nonvar(Closing_Balance),
nonvar(Repayment_Amount),
Closing_Balance >= Repayment_Amount,
\+find_fact2(Installment_Cell1, next, _, [Installment_Cell1:Installment_Cell]) 
| 
debug(chr_hp, "if closing balance is greater than or equal to repayment amount, there should be another installment after it.~n", []), 
fact(Installment_Cell, next, _).


% if opening_balance of the installment is less than the cash price of the arrangement, there should be another installment before it
rule, 
	fact(HP, a, hp_arrangement), 
	fact(HP, cash_price, Cash_Price), 
	fact(HP, installments, Installments), 
	fact(Installment_Cell, list_in, Installments), 
	fact(Installment_Cell, value, Installment), 
	fact(Installment, opening_balance, Opening_Balance) 
	==> 
	nonvar(Cash_Price), 
	nonvar(Opening_Balance), 
	Opening_Balance < Cash_Price, 
	\+find_fact2(Installment_Cell1, prev, _, [Installment_Cell1:Installment_Cell]) 
	| 
	debug(chr_hp, "if opening balance is less than the cash price of the arrangement, there should be another installment before it.~n", []), 
	fact(Installment_Cell, prev, _). 

% this is handled by the list theory
% if the index of an installment is the same as the number of installments, then it's the last installment
rule, fact(HP, a, hp_arrangement), fact(HP, number_of_installments, Number_Of_Installments), fact(HP, installments, Installments), fact(Installment, list_in, Installments), fact(Installment, list_index, Number_Of_Installments) ==> fact(Installments, last, Installment).


% if number of installments is nonvar then you can generate all the installments
rule, 
	fact(HP, a, hp_arrangement), 
	fact(HP, number_of_installments, Number_Of_Installments), 
	fact(HP, installments, Installments) 
	==> 
	\+'$enumerate_constraints'(block), 
	nonvar(Number_Of_Installments) 
	| 
	generate_installments(Installments, Number_Of_Installments).
*/
