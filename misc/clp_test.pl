:- use_module(library(clpq)).
:- use_module('../lib/doc_core', [doc/3, doc_clear/0, doc_add/3]).
:- use_module('../lib/doc', [doc_new_uri/1]).
:- use_module('../lib/files', [bump_tmp_directory_id/0]).
:-  op(  1,  xfx,  [  .. ]).
:-  op(  1,  fx,   [  #  ]).

last([Last], Last).
last([_ | [Y | Rest]], Last) :-
	last([Y | Rest], Last).

clp_sum(_, [], 0).
clp_sum(P, [X | Rest], Sum) :-
	(
		call(P, X, N0)
	->
		{N = N0}
	;
		N = 0
	),
	clp_sum(P, Rest, Rest_Sum),
	{Sum = N + Rest_Sum}.

between(Start, End, Value) :-
	{Start =< Value},
	{Value =< End}.

after(Reference, Date) :-
	{ Reference =< Date }.

maybe_float(X, X_Float) :- 
	(
		var(X)
	->
		X_Float = X
	;
		X_Float is round(float(X))
	).


/*
you will supply the transactions and the chart of accounts as separate documents along with the hire purchase documents
probably a separate document describes the relations between the installments and the transactions

*/

% if it's a var then it's too weak,
% if it's a bnode then it's too strong

assert_object(hp_installment, Installment) :-
	doc_new_uri(Installment),
	doc_add(Installment, a, hp_installment),
	doc_add(Installment, arrangement, _),
	doc_add(Installment, installment_number, _),
	doc_add(Installment, opening_date, _),
	doc_add(Installment, opening_balance, _),
	doc_add(Installment, interest_amount, _),
	doc_add(Installment, installment_amount, _),
	doc_add(Installment, closing_date, _),
	doc_add(Installment, closing_balance, _),
	doc_add(Installment, total_payments, _),
	doc_add(Installment, total_interest, _),
	doc_add(Installment, current_liability_balance, _),
	doc_add(Installment, noncurrent_liability_balance, _),
	doc_add(Installment, current_unexpired_interest, _),
	doc_add(Installment, noncurrent_unexpired_interest, _),
	doc_add(Installment, repayment_balance, _),
	doc_add(Installment, unexpired_interest, _),
	doc_add(Installment, liability_balance, _),
	doc_add(Installment, installment_type, _).

assert_object(hp_arrangement, HP) :-
	doc_new_uri(HP),
	doc_add(HP, a, hp_arrangement),
	doc_add(HP, period, _),				% ex. ratio of repayment_period / interest_period; ex. month/year = 1/12
	doc_add(HP, repayment_period, _),	% ex. monthly installments
	doc_add(HP, interest_period, _),	% ex. 13% interest per year
	doc_add(HP, begin_date, _),
	doc_add(HP, end_date, _),
	doc_add(HP, hp_duration, _),
	doc_add(HP, cash_price, _),
	doc_add(HP, number_of_installments, _),
	doc_add(HP, interest_rate, _),
	doc_add(HP, repayment_amount, _),
	doc_add(HP, final_balance, _),
	doc_add(HP, installments, _),
	doc_add(HP, total_payments, _),
	doc_add(HP, total_interest, _),
	doc_add(HP, current_liability, _),
	doc_add(HP, noncurrent_liability, _),
	doc_add(HP, hp_current_unexpired_interest, _),
	doc_add(HP, hp_noncurrent_unexpired_interest, _),
	doc_add(HP, hp_repayment_balance, _),
	doc_add(HP, hp_unexpired_interest, _),
	doc_add(HP, hp_liability_balance, _).

assert_object(time_period, Period) :-
	doc_new_uri(Period),
	doc_add(Period, a, time_period),
	doc_add(Period, start_date, _),
	doc_add(Period, end_date, _),
	doc_add(Period, duration, _).

parse_children([], []).
parse_children([Child | Rest], [Parsed_Child | Parsed_Rest]) :-
	parse_constraint(Child, Parsed_Child),
	parse_children(Rest, Parsed_Rest).

query_subjects(Constraint, Parsed_Constraint) :-
	Constraint =.. [Node | Children],
	(
		Node = '..'
	->
		(	
			Children = [Object, Field]
		->	doc(Object, Field, Parsed_Constraint)
		;	throw("'..'/2 takes two arguments")
		)
	;
		(
			parse_children(Children, Parsed_Children),
			Parsed_Constraint =.. [Node | Parsed_Children]
		)
	).
	
to_clp(A + B, X + Y) :-
	to_clp(A, X),
	to_clp(B, Y).

to_clp(A + B, X + Y) :-
	doc(A, a, value),
	doc(B, a, value),
	doc(A, unit, U),
	doc(B, unit, U2),
	(U = U2 -> true ; throw(unit_mismatch)),
	doc(A, amount, X),
	doc(B, amount, Y).
/*
to_clp(A, A) :-
	is_number(A).
*/
to_clp(A = B, X = Y) :-
	to_clp(A, X),
	to_clp(B, Y).


#(Constraint) :-
	/* this is gonna have to recurse on the tree and either post an actual clp constraint, or just call a pred that does,
for example value_add etc*/
	query_subjects(Constraint, Constraint2),
	to_clp(Constraint2, Clp),
	{Clp},
	constraint_add(Constraint2)
	
.

test2/*(
	HP_Begin_Date,				% currently integer-valued; lacking date/time dimensional stuff
	HP_Payment_Type,			% 0 = advance; 1 = arrears
	HP_Cash_Price,
	HP_Duration,
	HP_Repayment_Period,		
	HP_Repayment_Amount,
	HP_Interest_Period,
	HP_Interest_Rate,
	HP_RDF_Installments,
	HP_Number_Of_Installments,
	HP_End_Date,
	HP_Total_Interest,
	HP_Total_Payments,
	Report_Period_Start_Date,
	Report_Period_End_Date,
	Report_Period_Duration,
	_HP_Account,					% chart of accounts to be provided as separate document
	_Transactions,				% transactions ledger to be provided as separate document
	%Matches,
	HP_Liability_Balance,
	HP_Repayment_Balance,
	HP_Unexpired_Interest,
	HP_Current_Unexpired_Interest,
	HP_Noncurrent_Unexpired_Interest,
	HP_Current_Liability,
	HP_Noncurrent_Liability,
	HP_Final_Balance
)*/ :-
	% constraints about the periods involved in the arrangement
	% should maybe do something with member/2 i.e. unify and if fail then assert
	% just some doc setup
	doc_clear,
	bump_tmp_directory_id,

	% add hp arrangement information
	assert_object(hp_arrangement,HP),

	% add context information
	assert_object(time_period, Report_Period),

	#(HP..period = HP..repayment_period / HP..interest_period),
	#(HP..end_date = HP..begin_date + HP..hp_duration),
	#(Report_Period..end_date = Report_Period..end_date + Report_Period..duration),


	% generate the installments list structure
	% this part is tricky because we're asserting graph structure and list structure as part of the constraints.
	% want the rest of the fields to be implicitly asserted by the fact that it's an hp_installment	

	% relate first installment to the list
	assert_object(hp_installment, Installment_1),
	doc(Installment_1, arrangement, HP),
	#(Installment_1..installment_number = 1),
	#(Installment_1..opening_date = HP..begin_date + (HP..payment_type * HP..repayment_period)),
	#(Installment_1..opening_balance = HP..cash_price),
	#(Installment_1..installment_amount = HP..repayment_amount), % unless it's a balloon payment
	#(Installment_1..total_payments = Installment_1..installment_amount),
	#(Installment_1..total_interest = Installment_1..interest_amount),

	% generate the actual list / graph structure	
	Installments = [Installment_1 | Installments_Rest],
	gen_hp_installments(HP, Installment_1, Installments_Rest),

	% relate last installment to the list
	last(HP_Installments, Installment_N),
	#(Installment_N..closing_date = HP..end_date),
	#(Installment_N..installment_number = HP..number_of_installments),
	#(Installment_N..closing_balance = HP..final_balance),
	#(Installment_N..total_payments = HP..total_payments),
	#(Installment_N..total_interest = HP..total_interest),




	% (HP-)global constraints
	%{ HP_Cash_Price = Opening_Balance },
	%{ Opening_Date = HP_Begin_Date + (HP_Payment_Type * HP_Repayment_Period)}, 
	%{ HP_Total_Payments = HP_Cash_Price + HP_Total_Interest - HP_Final_Balance},
	%{ HP_Liability_Balance = HP_Repayment_Balance + HP_Unexpired_Interest},
	%{ HP_Repayment_Balance = HP_Current_Liability + HP_Noncurrent_Liability},
	%{ HP_Unexpired_Interest = HP_Current_Unexpired_Interest + HP_Noncurrent_Unexpired_Interest},

	#(HP..total_payments = HP..cash_price + HP..total_interest - HP..final_balance),
	#(HP..liability_balance = HP..repayment_balance + HP..unexpired_interest),
	#(HP..repayment_balance = HP..current_liability + HP..noncurrent_liability),
	#(HP..unexpired_interest = HP..current_unexpired_interest + HP..noncurrent_unexpired_interest),

	% needs help in order to infer a repayment amount needed to pay off an arrangement in a given number of installments
	repayment_formula(HP),
	/*
	repayment_formula(
		HP_Repayment_Amount,
		HP_Cash_Price,
		HP_Interest_Rate,
		HP_Period,
		HP_Number_Of_Installments,
		HP_Final_Balance
	), 
	*/
	% context-dependent aggregate constraints
	% better way to write these constraints?
	% probably at least needs a higher-level way of talking about "current" vs. "noncurrent"
	% but it's already clunky anyway because we have to assert the constraints by looping over a list instead of
	% declaratively stating a relation between successive items
	%
	% also hard to simplify because it's necessarily parameterized, we're not gonna store the values for all combinations of
	% start and end dates..., but we are expecting to get the parameters in the documents defining the arrangement...,
	% so we can potentially just attach these values to the installments...
	doc(HP, current_liability, Current_Liability),
	clp_sum(
		[Installment,Payment]>>(
			doc(Installment, installment_amount, Payment),
			doc(Installment, closing_date, Closing_Date),
			between(Report_Period_Start_Date, Report_Period_End_Date, Closing_Date)
		), 
		Installments, 
		Current_Liability
	),


	doc(HP, noncurrent_liability, Noncurrent_Liability),
	clp_sum(
		[Installment, Payment]>>(
			doc(Installment,installment_amount,Payment),
			doc(Installment,closing_date,Closing_Date),
			after(Report_Period_End_Date, Closing_Date)
		),
		Installments,
		Noncurrent_Liability
	),

	doc(HP, current_unexpired_interest, Current_Unexpired_Interest),
	clp_sum(
		[Installment,Interest]>>(
			doc(Installment,interest_amount,Interest),
			doc(Installment,closing_date,Closing_Date),
			between(Report_Period_Start_Date, Report_Period_End_Date, Closing_Date)
		), 
		Installments, 
		Current_Unexpired_Interest
	),

	doc(HP, noncurrent_unexpired_interest, Noncurrent_Unexpired_Interest),
	clp_sum(
		[Installment, Interest]>>(
			doc(Installment,interest_amount,Interest),
			doc(Installment,closing_date,Closing_Date),
			after(Report_Period_End_Date, Closing_Date)
		),
		Installments,
		Noncurrent_Unexpired_Interest
	)%,
	%!%,


	% this is separate, this is part of the document-oriented logic

	% relate installments to the set of transactions
	% * a hire purchase arrangement creates the constraints that there "should" be some transactions in the ledger, at any given date
	% * a transaction matches an installment if it satisfies some constraints
	%   * right now we have very loose constraints
	%   * correct amount, to the correct account, within the installment period
	%   * mainly just checking that some fields match
	%   * classifying partial matches
	% {Opening_Date =< Transaction_Date},
	% {Transaction_Date <= Closing_Date},


	/*
	findall(
		match(Installment, Installment_Transactions),
		(
			member(This_Installment, Installments),
			Installment = installment(_, Opening_Date, _, _, _, Closing_Date, _),
			findall(
				installment_transaction(Transaction,
				(
					member(This_Transaction, Transactions),
					This_Transaction = transaction(_,Transaction_Date,_),
					{Opening_Date =< Transaction_Date},
					{Transaction_Date =< Closing_Date}
				),
				Installment_Transactions
			)
		),	
		Matches
	)
	*/
	% transaction(Transaction_Id, Transaction_Date, Installment_Amount, ...)
	% document operations? insert, remove...; operations come in inverse pairs
	

	% going backwards from transactions to installment plan..
	% * can't infer that it's a hire-purchase record
	% * can at best infer that there's a monthly payment
	% * couldn't detect balloon payments
	% * maybe it could if annotated with enough other data? 
	%   * but it would have to be equivalent information to the hire purchase arrangement anyway
	% * totally in the "theorizing" rather than "deducing" territory in any case

	% right now we have very loose constraints
	% do corrections
	
	.


gen_hp_installments(HP, Previous_Installment, [Installment | Rest]) :-
	% create current installment
	assert_object(hp_installment, Installment),


	% relate installment to hp arrangement and previous installment in graph
	doc(Installment, arrangement, HP),
	doc_add(Installment, previous, Previous_Installment),
	doc_add(Previous_Installment, next, Installment),



	% add constraints between current and previous installment fields
	#(Installment..opening_balance = Previous_Installment..closing_balance),

	#(Installment..opening_date = Previous_Installment..closing_date + 1),

	#(Installment..closing_date = Installment..opening_date + HP..repayment_period - 1),

	#(Installment..installment_number = Previous_Installment..installment_number + 1),

	#(Installment..installment_amount = HP..repayment_amount),

	#(Installment..interest_amount = Installment..opening_balance * HP..interest_rate * HP..period),

	#(Installment..closing_balance = Installment..opening_balance + Installment..interest_amount - HP..repayment_amount),

	#(Installment..total_interest = Previous_Installment..total_interest + Installment..interest_amount),

	#(Installment..total_payments = Previous_Installment..total_payments + HP..repayment_amount),





	% global constraints from algebraic manipulation of summation formulas
	% an algebraic short-cut to closing balance of any given installment number I
	% needs to account for balloon payments
	% general_closing_balance_formula(Closing_Balance, HP_Cash_Price, HP_Interest_Rate, HP_Period, Installment_Number, HP_Repayment_Amount),




	% dealing with balloon payments vs. regular payments
	%{Installment_Type = 0},
	% messy: not very CLP-like ?
	/*
	(
		Repayment_Amount = HP_Repayment_Amount
	->
		Installment_Type = 0 % regular
	;
		Installment_Type = 1 % balloon
	),
	*/
	% unless we can maybe frame it algebraically?
	%{Repayment_Amount = (1 - Installment_Type)*HP_Repayment_Amount + Installment_Type*Balloon_Amount},
	%	* where Installment_Type in {0,1}





	% inequalities and bounds
	% can maybe be used eventually as part of termination analysis

	% closing_balance must be decreasing
	#(Installment..closing_balance < Previous_Installment..closing_balance),

	% lower bounds on closing balance
	#(HP..final_balance =< Installment..closing_balance),

	% upper bounds on closing balances
	% {Previous_Opening_Balance < smallest principal for which the repayment amount would diverge},





	% and finally recurse to generate more installments unless we've generated all of them:

	% what's up with this conditional...; not very CLP-like.. ?
	% what conditions actually determine the last installment?
	doc(Installment, installment_number, Installment_Number),
	doc(HP, number_of_installments, HP_Number_Of_Installments),
	(
		Installment_Number < HP_Number_Of_Installments
	->
		gen_hp_installments(HP, Installment, Rest)
	;
		Rest = []
	), !.


% combine these two formulas somehow?
% not sure if it can infer N...
% it can infer N approximately... 
% needs to also relate to the total number of payments
% we know N is the total number of payments when Balance = F
general_closing_balance_formula(Balance, P, R, T, N, A) :-
	{ Balance = ((P * ((1 + R * T)^N)) - A * (((1 + R * T)^N) - 1)/(R * T))}.


% formula requires simplification based on geometric series sum formula, so, it's forgiveable that CLP couldn't solve this;
% main thing is that we can just pile on these constraints and easily just keep adding knowledge and relations
repayment_formula(HP) :-
	doc(HP, a, hp_arrangement),
	A = HP..repayment_amount,
	P = HP..cash_price,
	R = HP..interest_rate,
	T = HP..period,
	N = HP..number_of_transactions,
	F = HP..final_balance,
	% not sure if there's a simpler/better way to write this formula?
	#( A = ((P * ((1 + R * T)^N) - F) * R * T)/((1 + R * T)^N - 1) }.

% now needs to handle all the installments...
%  * even when it isn't given Number_Of_Installments or a complete list of installments
% relate Number_Of_Installments to the count of the installments
% insert & detect balloon payments; infer data even in the presence of balloon installments
% corrections
% dealing with non-zero final balance
% if-then-else with CLP when the conditions might be variable ?
% handling units with CLP?
% handling date/time stuff with CLP?
% numeric stuff; limited-precision arithmetic relations; rounding
% * we have a basic way of dealing with the approximation errors while still allowing CLP(Q) to work
% proof-tracing
% document-oriented interface
