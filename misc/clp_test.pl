:- use_module(library(clpq)).
:- use_module('../lib/doc_core', [doc/3, doc_clear/0, doc_add/3]).
:- use_module('../lib/doc', [doc_new_uri/1]).
:- use_module('../lib/files', [bump_tmp_directory_id/0]).

%:- doc_clear.
help(test) :-
	writeln("test(HP_Begin_Date, HP_Payment_Type, HP_Cash_Price, Opening_Balance, Interest_Rate, Repayment_Period, Interest_Period, Interest_Amount, Repayment_Amount, Closing_Balance, Opening_Date, Closing_Date, Installment_Number)").
help(test2) :-
	writeln("test2(HP_Begin_Date, HP_Payment_Type, HP_Cash_Price, HP_Duration, HP_Repayment_Period, HP_Repayment_Amount, HP_Interest_Period, HP_Interest_Rate, HP_Installments, HP_Number_of_Installments, HP_End_Date, HP_Total_Interest, HP_Total_Payments, Current_Date, Report_Period_Start_Date, Report_Period_End_Date, Report_Period_Duration, HP_Account, Transactions, HP_Liability_Balance, HP_Repayment_Balance, HP_Unexpired_Interest, HP_Current_Unexpired_Interest, HP_Noncurrent_Unexpired_Interest, HP_Current_Liability, HP_Noncurrent_Liability)"). 

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


hp_installment_number(installment(Number,_,_,_,_,_,_), Number).
hp_installment_opening_date(installment(_,Opening_Date,_,_,_,_,_), Opening_Date).
hp_installment_opening_balance(installment(_,_,Opening_Balance,_,_,_,_), Opening_Balance).
hp_installment_interest_amount(installment(_,_,_,Interest_Amount,_,_,_), Interest_Amount).
hp_installment_payment(installment(_,_,_,_,Payment,_,_), Payment).
hp_installment_closing_date(installment(_,_,_,_,_,Closing_Date,_), Closing_Date).
hp_installment_closing_balance(installment(_,_,_,_,_,_,Closing_Balance), Closing_Balance).

/*
you will supply the transactions and the chart of accounts along with the hire purchase documents
probably a separate document describes the relations between the installments and the transactions

*/

% if it's a var then it's too weak,
% if it's a bnode then it's too strong

assert_object(hp_installment, Installment) :-
	writeln("hp_installment"),
	doc_new_uri(Installment),
	format("new uri: ~w~n", [Installment]),
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
	writeln("hp_arrangement"),
	doc_new_uri(HP),
	format("new uri: ~w~n", [HP]),
	doc_add(HP, a, hp_arrangement),
	doc_add(HP, period, _),
	doc_add(HP, repayment_period, _),
	doc_add(HP, interest_period, _),
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



test2(
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
) :-
	% constraints about the periods involved in the arrangement
	% should maybe do something with member/2 i.e. unify and if fail then assert
	doc_clear,
	bump_tmp_directory_id,
	writeln("clear"),
	assert_object(hp_arrangement,HP),
	writeln("asserted object"),

	doc(HP, period, HP_Period),
	doc(HP, repayment_period, HP_Repayment_Period),
	doc(HP, interest_period, HP_Interest_Period),
	doc(HP, begin_date, HP_Begin_Date),
	doc(HP, end_date, HP_End_Date),
	doc(HP, hp_duration, HP_Duration),
	doc(HP, cash_price, HP_Cash_Price),
	doc(HP, number_of_installments, HP_Number_Of_Installments),
	doc(HP, interest_rate, HP_Interest_Rate),
	doc(HP, repayment_amount, HP_Repayment_Amount),
	doc(HP, final_balance, HP_Final_Balance),
	doc(HP, installments, HP_RDF_Installments),
	doc(HP, total_payments, HP_Total_Payments),
	doc(HP, total_interest, HP_Total_Interest),
	doc(HP, current_liability, HP_Current_Liability),
	doc(HP, noncurrent_liability, HP_Noncurrent_Liability),
	doc(HP, hp_current_unexpired_interest, HP_Current_Unexpired_Interest),
	doc(HP, hp_noncurrent_unexpired_interest, HP_Noncurrent_Unexpired_Interest),
	doc(HP, hp_repayment_balance, HP_Repayment_Balance),
	doc(HP, hp_unexpired_interest, HP_Unexpired_Interest),
	doc(HP, hp_liability_balance, HP_Liability_Balance),
	writeln("doc"),

	doc_new_uri(Context),	
	doc_add(Context, a, document_context),
	doc_add(Context, report_period_start_date, Report_Period_Start_Date),
	doc_add(Context, report_period_end_date, Report_Period_End_Date),
	doc_add(Context, duration, Report_Period_Duration),	
	writeln("context doc"),

	{ HP_Period = HP_Repayment_Period / HP_Interest_Period },

	% any period has a start, end and duration
	{ HP_End_Date = HP_Begin_Date + HP_Duration },
	{ Report_Period_End_Date = Report_Period_Start_Date + Report_Period_Duration },

	% constraints relating the arrangement parameters to the first installment
	% note this is actually asserting the existence of the installment object..;
	% how to do the same asserting with triples properly? basically we need to generate a bnode or something
	% but how does this interact with whatever it might need to unify with?
	%First_Installment = installment(1, Opening_Date, Opening_Balance, _, _, _, _),


	% should maybe be a rule stating that whichever installment happens to be the first, then it's related to
	% the HP paramaters in a particular way; but that rule also needs to be bidirectional, so if some 
	% installment is related to the HP paramters in a particular way, then it's the first.
	% similarly we need to know when an installment is the last one.

	% needs to basically be a "delayed create if not existing" operation
	% so if it exists, then it needs to match with it;
	% it can't just match with anything, say ex. there's only one installment asserted
	% and the installment number is missing, but other values are specified, it needs to
	% satisfy the constraints. 


	% want the rest of the fields to be implicitly asserted by the fact that it's an hp_installment	
	assert_object(hp_installment, First_RDF_Installment),
	writeln("assert first installment"),
	doc(First_RDF_Installment, arrangement, HP),
	doc(First_RDF_Installment, installment_number, 1),
	doc(First_RDF_Installment, opening_date, Opening_Date),
	doc(First_RDF_Installment, opening_balance, Opening_Balance),
	doc(First_RDF_Installment, installment_amount, HP_Repayment_Amount),
	doc(First_RDF_Installment, interest_amount, First_Interest_Amount),
	doc(First_RDF_Installment, total_payments, HP_Repayment_Amount),
	doc(First_RDF_Installment, total_interest, First_Interest_Amount),
	writeln("docs1"),
	
	% this part is tricky because we're asserting graph structure and list structure as part of the constraints.
	HP_RDF_Installments = [First_RDF_Installment | HP_RDF_Installments_Rest],
	writeln("before_gen_hp_installments"),
	%fail,
	gen_hp_installments(HP, First_RDF_Installment, HP_RDF_Installments_Rest),
	writeln("gen_hp_installments done"),
	last(HP_RDF_Installments, Last_RDF_Installment),
	% if First_Installment and Last_Installment both satisfiy each other's constraint's, then they're the same object
	doc(Last_RDF_Installment, installment_number, HP_Number_Of_Installments),
	doc(Last_RDF_Installment, closing_balance, Actual_Final_Balance),
	doc(Last_RDF_Installment, total_payments, HP_Total_Payments),
	doc(Last_RDF_Installment, total_interest, HP_Total_Interest),
	% HP_Final_Balance is a float when given as an input so we get errors like:
	% ERROR: Unhandled exception: type_error(_172352=5.11,2,'a rational number',5.11)
	% this is basically just a hack to rationalize HP_Final_Balance for the unification
	{ HP_Final_Balance = Actual_Final_Balance},
	doc(Last_RDF_Installment, closing_date, HP_End_Date),
	%
	{ HP_Cash_Price = Opening_Balance },
	{ Opening_Date = HP_Begin_Date + (HP_Payment_Type * HP_Repayment_Period)}, 

	% needs help in order to infer a repayment amount needed to pay off an arrangement in a given number of installments
	% repayment_formula... should it really take arguments? it's just kind of a general condition that holds about hp arrangements
	repayment_formula(HP),
	%repayment_formula(HP_Repayment_Amount, HP_Cash_Price, HP_Interest_Rate, HP_Period, HP_Number_Of_Installments, HP_Final_Balance),


	% Non-CLP workaround describing the structure of the installments table...
	% generate the list of installments along with arithmetic constraints on each installment
	% how to express in terms of CLP? ex.. we might not know the length of the list and we might not know the number of installments
	
	%HP_Installments = [ First_Installment | _],
	%gen_hp_installments(HP_Cash_Price, HP_Interest_Rate, HP_Period, HP_Repayment_Period, HP_Repayment_Amount, HP_Number_Of_Installments, 0, HP_Cash_Price, Dummy_Closing_Date, HP_Installments),
	%writeln("got through installments"),
	%last(HP_Installments, Last_Installment),
	%Last_Installment = installment(HP_Number_Of_Installments, _, _, _, _, HP_End_Date, Actual_Final_Balance),
	%{ HP_Final_Balance = Actual_Final_Balance }, % basically a float->rat hack since HP_Final_Balance comes from the input, they don't directly unify
	% should do a preprocessing step to rationalize all input values instead..
	% Constraints defining aggregates/sums
	/*
	clp_sum(
		[Installment, Payment]>>(
			doc(Installment, installment_amount, Payment)
		),
		HP_RDF_Installments,
		HP_Total_Payments
	),
	clp_sum(
		[Installment, Interest]>>(
			doc(Installment, interest_amount, Interest)
		),
		HP_RDF_Installments,
		HP_Total_Interest
	),	
	*/
	{ HP_Total_Payments = HP_Cash_Price + HP_Total_Interest - HP_Final_Balance},

	
	% note: 
	%  * just like in Murisi's code these values have nothing to do with what payments have *actually* been made.
	%  * this is fine but we probably also need a version of these values that do account for actual payments

	% also note:
	%  * all of this is context-dependent
	{ HP_Liability_Balance = HP_Repayment_Balance + HP_Unexpired_Interest},
	{ HP_Repayment_Balance = HP_Current_Liability + HP_Noncurrent_Liability},
	{ HP_Unexpired_Interest = HP_Current_Unexpired_Interest + HP_Noncurrent_Unexpired_Interest},

	% better way to say this?
	% probably at least needs a higher-level way of talking about "current" vs. "noncurrent"
	% but it's already clunky anyway because we have to assert the constraints by looping over a list instead of
	% declaratively stating a relation between successive items
	%
	% also hard to simplify because it's necessarily parameterized, we're not gonna store the values for all combinations of
	% start and end dates..., but we are expecting to get the parameters in the documents defining the arrangement...,
	% so we can potentially just attach these values to the installments...
	clp_sum(
		[Installment,Payment]>>(
			doc(Installment, installment_amount, Payment),
			doc(Installment, closing_date, Closing_Date),
			/*
			hp_installment_payment(Installment,Payment),
			hp_installment_closing_date(Installment,Closing_Date),
			*/
			between(Report_Period_Start_Date, Report_Period_End_Date, Closing_Date)
		), 
		HP_RDF_Installments, 
		HP_Current_Liability
	),
	clp_sum(
		[Installment, Payment]>>(
			doc(Installment,installment_amount,Payment),
			doc(Installment,closing_date,Closing_Date),
			after(Report_Period_End_Date, Closing_Date)
		),
		HP_RDF_Installments,
		HP_Noncurrent_Liability
	),
	clp_sum(
		[Installment,Interest]>>(
			doc(Installment,interest_amount,Interest),
			doc(Installment,closing_date,Closing_Date),
			between(Report_Period_Start_Date, Report_Period_End_Date, Closing_Date)
		), 
		HP_RDF_Installments, 
		HP_Current_Unexpired_Interest
	),
	clp_sum(
		[Installment, Interest]>>(
			doc(Installment,interest_amount,Interest),
			doc(Installment,closing_date,Closing_Date),
			after(Report_Period_End_Date, Closing_Date)
		),
		HP_RDF_Installments,
		HP_Noncurrent_Unexpired_Interest
	),
	writeln("done..."),
	!%,


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
	writeln("repayment formula... 1"),
	doc(HP, a, hp_arrangement),
	doc(HP, repayment_amount, Repayment_Amount),
	doc(HP, cash_price, P),
	doc(HP, interest_rate, R),
	doc(HP, period, T),
	doc(HP, number_of_installments, N),
	doc(HP, final_balance, F),
	writeln("repayment formula..."),
	{ Repayment_Amount = ((P * ((1 + R * T)^N) - F) * R * T)/((1 + R * T)^N - 1) }.


repayment_formula(Repayment_Amount, P, R, T, N, F) :- 
	{ Repayment_Amount = ((P * ((1 + R * T)^N) - F) * R * T)/((1 + R * T)^N - 1) }.

/*
superformula(Balance, P, R, T, I, N, F, A, B, C) :-
	{ A = R * T },
	{ B = 1 + A },
	{ C = ((P * (B^N) - F) * A)/(B^N - 1)},	% repayment_formula
	{ Balance = P * (M ^ I) - C * ((M^N - 1)/(R * T)) }.

superformula2(Balance, P, R, T, I, N, F, A, B, C) :-
	{ A = R * T },
	{ B = 1 + A },
	{ C = ((P * (B^N) - F) * A)/(B^N - 1)},
	{ Balance = P * (B ^ I) - P * (B ^ N) + F }.
*/	


gen_hp_installments(HP, Previous_Installment, [Installment | Rest]) :-
	writeln("gen_hp_installments"),
	doc(HP, number_of_installments, HP_Number_Of_Installments),
	%doc(HP, cash_price, HP_Cash_Price),
	doc(HP, interest_rate, HP_Interest_Rate),
	doc(HP, period, HP_Period),
	doc(HP, repayment_amount, HP_Repayment_Amount),
	doc(HP, repayment_period, HP_Repayment_Period),
	%doc(HP, interest_period, HP_Interest_Period),

	doc(Previous_Installment, installment_number, Previous_Installment_Number),
	doc(Previous_Installment, closing_balance, Previous_Closing_Balance),
	doc(Previous_Installment, closing_date, Previous_Closing_Date),
	doc(Previous_Installment, total_interest, Previous_Total_Interest),
	doc(Previous_Installment, total_payments, Previous_Total_Payments),
	format("Previous installment -- ~w: ~w~n", [Previous_Installment_Number, Previous_Closing_Balance]),

	assert_object(hp_installment, Installment),
	doc(Installment, a, hp_installment),
	doc(Installment, installment_number, Installment_Number),
	doc(Installment, opening_date, Opening_Date),
	doc(Installment, opening_balance, Opening_Balance),
	doc(Installment, interest_amount, Interest_Amount),
	doc(Installment, installment_amount, Repayment_Amount),
	doc(Installment, closing_date, Closing_Date),
	doc(Installment, closing_balance, Closing_Balance),
	%doc(Installment, installment_type, Installment_Type),
	doc(Installment, total_interest, Total_Interest),
	doc(Installment, total_payments, Total_Payments),
	doc_add(Installment, previous, Previous_Installment),
	doc_add(Previous_Installment, next, Installment),

	{Opening_Balance = Previous_Closing_Balance},
	format("Previous installment -- ~w: ~w~n", [Previous_Installment_Number, Previous_Closing_Balance]),
	{Opening_Date = Previous_Closing_Date + 1},
	{Closing_Date = Opening_Date + HP_Repayment_Period - 1},
	{Installment_Number = Previous_Installment_Number + 1},
	{Interest_Amount = Opening_Balance * HP_Interest_Rate * HP_Period},
	{Closing_Balance = Opening_Balance + Interest_Amount - HP_Repayment_Amount},
	{Total_Interest = Previous_Total_Interest + Interest_Amount},
	{Total_Payments = Previous_Total_Payments + HP_Repayment_Amount},
	{HP_Repayment_Amount = Repayment_Amount},
	%{Installment_Type = 0},
	% messy:
	/*
	(
		Repayment_Amount = HP_Repayment_Amount
	->
		Installment_Type = 0 % regular
	;
		Installment_Type = 1 % balloon
	),
	*/
	%{Repayment_Amount = (1 - Installment_Type)*HP_Repayment_Amount + Installment_Type*_},
	%	* where Installment_Type in {0,1}
	% an algebraic short-cut to closing balance of any given installment number I
	% needs to account for balloon payments
	%general_closing_balance_formula(Closing_Balance, HP_Cash_Price, HP_Interest_Rate, HP_Period, Installment_Number, HP_Repayment_Amount),
	maybe_float(Installment_Number, I_Float),
	format("computed installment number: ~w~n", [I_Float]),
	% what's up with this conditional...
	(
		Installment_Number < HP_Number_Of_Installments
	->
		gen_hp_installments(HP, Installment, Rest)
	;
		Rest = []
	), !.


/*
gen_hp_installments(
	HP_Cash_Price,
	HP_Interest_Rate,
	HP_Period,
	HP_Repayment_Period,
	HP_Repayment_Amount,
	HP_Number_Of_Installments,
	Previous_Installment_Number,
	Previous_Closing_Balance,
	Previous_Closing_Date,
	[
		installment(
			Installment_Number,
			Opening_Date,
			Opening_Balance,
			Interest_Amount,
			HP_Repayment_Amount,
			Closing_Date,
			Closing_Balance
		) 
	| 
		Installments
	]
) :-
	
	{Opening_Balance = Previous_Closing_Balance},
	{Opening_Date = Previous_Closing_Date + 1},
	{Closing_Date = Opening_Date + HP_Repayment_Period - 1},
	{Installment_Number = Previous_Installment_Number + 1},
	{Interest_Amount = Opening_Balance * HP_Interest_Rate * HP_Period},
	{Closing_Balance = Opening_Balance + Interest_Amount - HP_Repayment_Amount},

	% an algebraic short-cut to closing balance of any given installment number I
	general_closing_balance_formula(Closing_Balance, HP_Cash_Price, HP_Interest_Rate, HP_Period, I, HP_Repayment_Amount),
	maybe_float(I, I_Float),
	format("computed installment number: ~w~n", [I_Float]),
	% what's up with this conditional...
	(
		Installment_Number < HP_Number_Of_Installments
	->
		gen_hp_installments(HP_Cash_Price, HP_Interest_Rate, HP_Period, HP_Repayment_Period, HP_Repayment_Amount, HP_Number_Of_Installments, Installment_Number, Closing_Balance, Closing_Date, Installments)
	;
		Installments = []
	).
*/

maybe_float(X, X_Float) :- 
	(
		var(X)
	->
		X_Float = X
	;
		X_Float is round(float(X))
	).


write_installments([]).
write_installments([installment(Installment_Number, Opening_Date, Opening_Balance, Interest_Amount, Closing_Date, Closing_Balance) | Rest]) :-
	Rounded_Opening_Balance is float(Opening_Balance),
	Rounded_Interest_Amount is float(Interest_Amount),
	Rounded_Closing_Balance is float(Closing_Balance),
	format("~w, ~w - ~w: ~w, ~w, ~w~n", [Installment_Number, Opening_Date, Closing_Date, Rounded_Opening_Balance, Rounded_Interest_Amount, Rounded_Closing_Balance]),
	write_installments(Rest).

% now needs to handle all the installments...
%  * even when it isn't given Number_Of_Installments or a complete list of installments
% relate Number_Of_Installments to the count of the installments
% insert & detect balloon payments; infer data even in the presence of balloon installments
% factoring small remaining balance into final installment
% if-then-else with CLP when the conditions might be variable ?
% handling units with CLP?
% handling date/time stuff with CLP?
% numeric stuff; limited-precision arithmetic relations; rounding
% * we have a basic way of dealing with the approximation errors while still allowing CLP(Q) to work
% proof-tracing
% RDF-ifying
