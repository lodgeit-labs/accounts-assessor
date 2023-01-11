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
	/*
	needs to handle:
		* dimensions
		* precision and tolerance
		* explanations
	*/
	query_subjects(Constraint, Constraint2),
	to_clp(Constraint2, Clp),
	{Clp},
	constraint_add(Constraint2)
	
.




test1(HP) :-
	% we get some input, how do we relate that to the hp?
	% really just want to add it into the doc so that we can start using it everywhere, so this entails
	% separating things out in the doc
	% that's where the doc/concept distinction came in
	% we can drop the ontology alignment step now because now a doc is just a tentative concept
	% so we can pose each individual triple in its own separate universe, and then start combining universes


hp1 :-
	%assert_object(hp_arrangement,HP),
	assert_object(hp_installment, Installment_1),

	% for every installment period, there should be some transactions (on some accounts)...
	% get an "expected" ledger, which gets compared with actual ledger, leading to corrections, etc...
	% 

	% generating a generic debt obligation concept; encapsulate some of these default curve parameters
	
	% so all of this basically just defining some (*expected*) parameters/constraints on a ledger
	% just more curve parameters
	HP..installments..opening_balance = HP..cash_price % just reference these directly? maybe not
	% opening_balance = cash_price due to purchasing something that has that price

	HP..installments..ending_balance = HP..final_balance % 

	% this is only the case if there actually are installments, which is not the case if ex.. cash_price = final_balance
	%#(Installment_1..installment_number = 1), % don't need this if we have list-index syntax
	% don't need list-index syntax if we have function-application syntax
	HP..installments[1]..opening_date = HP..begin_date + (HP..payment_type * HP..repayment_period)),
	HP..installments[-1]..closing_date = HP..end_date), % should be derived? maybe not, but maybe a more structured way of defining/relating periods
	% needs help in order to infer a repayment amount needed to pay off an arrangement in a given number of installments
	repayment_formula(HP).

	% these are just random ways to explain what's happening on a curve
	% should just get a generic curve object and then bidirectionality between explanations & constraints



	% relationship between dimensional (x / y)and functions/foralls y -> x 
	% this should just be a rate-like dimensional quantity applied to the HP_Account balance, and we can get an account out of it
	% Interest_Amount : (Currency from HP Account to Interest Account) per Compounding Interval	
	% it has these simple dimensions, it's value is just time-varying; the rate-of-change of Interest Amount is non-zero
	% (d Interest_Amount(t) / dt)(t') = Nominal_Rate*HP_Account(t') ((Currency from HP Account to Interest Account) per Compounding Interval) per Interest Interval...
	% (d Interest_Amount(t) / dt)(t') = Nominal_Rate*HP_Account(t') (Currency from HP Account to Interest Account) per (Compounding Interval * Interest Interval)
	% (d Interest_Amount(t) / dt)(t') = Nominal_Rate*HP_Account(t') (Currency from HP Account to Interest Account) per (Compounding Interval^2 * (Interest Interval/Compounding Interval))
	% (d Interest_Amount(t) / dt)(t') = Nominal_Rate*HP_Account(t')*(Compounding Interval/Interest Interval)*(Currency from HP Account to Interest Account) per (Compounding Interval^2)
	% so it can automatically make sense of this; we can provide an "interest-like" dimensional quantity to automate the process of sorting out mixing different
	% rates in the same formula

	% then generating accounts by applying these rate-like quantities to balances;

	
	/*
	% Interest dimensions related to interest semantics through system of differential equations:
	% related to exponentials and geometric series..
	HP_Account(t) 
		= Interest_Account(t) + Payment_Account(t)   		 						: Currency

	(d/dt Interest_Account(t))[t'] 
		= Interest_Amount(t')       		 										: (Currency from Interest Account to HP Account) per Compounding Interval

	(d^2/dt^2 Interest_Account(t))[t'] 
		= Nominal_Rate*HP_Account(t')*(Compounding Interval / Interest Interval) 	: (Currency from Interest Account to HP Account) per Compounding Interval^2

	(d/dt Payment_Account(t))[t'] 
		= Payment_Amount(t')														: (Currency from HP Account to Payment Account) per Installment Interval

	(d^2/dt^2 Interest_Account(t))[t'] 
		= 0																			: (Currency from HP Account to Payment Account) per Installment Interval^2
	*/


	forall T,
		T in Compounding_Intervals,
	=>
	exists (uniquely):
		transaction(T, Interest_Account, Interest_Amount, 0),
		transaction(T, HP_Account, 0, Interest_Amount),
	where:
	% this should be handling units
	% typecasting an absolute time-period as a relative duration
	% just a random formula, and we've got others; we can generalize this out
	#(Interest_Amount = Installment..opening_balance * HP..interest_rate * T), %
	% T : abstract 


	% this should just be a rate-like dimensional quantity applied to the HP_Account balance, and we can get an account out of it
	% Payment_Amount : (Currency from Payment Account to HP Account) per Installment Interval)
	% (d Payment_Amount(t) / dt)(t') = 0
	forall T,
		T in Installment_Intervals,
	=>
	should exists (uniquely):
		transaction(T, Payment_Account, 0, Payment_Amount),		% formula components of balance curve parameters are tied to accounts
		transaction(T, HP_Account, Payment_Amount, 0)			% ...
	],
	where:
	% corresponds to operation of inserting arbitrary element at arbitrary location
	% also corresponds to classification of objects
	% maybe shouldn't conflate the two, we wouldn't have "insert submarine", we would just have "insert",
	% and the object happens to be either balloon, submarine, or regular, relative to some "expected" payment amount
	#(Payment_Amount = HP..payment_amount or some balloon amount). % should actually be explicitly parameterized by the payment amount
																	% that it's a balloon relative to; so we can generalize this out
	% so this is a task of: interject arbitrary pattern of elements into a list and continue to satisfy the constraints
	% in order to do that, it might sometimes require making the equations flexible enough, ex.. making repayment_formula take 
	% balloon payments into account in order to calculate what "regular" payment amount should be required in order to exactly fill in the 
	% gaps between a given pattern of insertions

	% although we should also be making use of approximate & iterative methods rather than just algebraic methods


	%P_(i+1) = P + P*r*t - R
	%two things affecting HP_Account balance in the formula, spawns two related accounts, and then 4 more based on current/noncurrent


	% the rest should be derived from this;

	% hp account
	% 	
	% liability balance account			% repayment balance + unexpired_interest
	% repayment balance account			% how much is left to pay           % credit
	% unexpired interest account		% how much interest is left to pay  % debit
	% current interest amount account	% how much interest is left to pay in current period
	% current repayment account			% ...
	% noncurrent interest account
	% noncurrent repayment account

	% missing payments account
	
	% closing_balance must be decreasing
	% if Closing_Balance < Opening_Balance, then the arrangement would be payed off in a finite number of installments
	% if Closing_Balance >= Opening_Balance, then the arrangement would never be payed off

	% should be that balance of installment transaction set should be negative
	%#(Installment..closing_balance < Previous_Installment..closing_balance), % should be derived?
	#(Installment..closing_balance < Installment..opening_balance) % more self-contained at least
	% can it derive that this is an immediate termination check?

	% lower bounds on closing balance
	#(HP..final_balance =< Installment..closing_balance),

	% upper bounds on opening balances
	%
	% {opening_balance < smallest principal for which the repayment amount would diverge or remain equal},




hp(HP) :-
	% constraints about the periods involved in the arrangement
	% should maybe do something with member/2 i.e. unify and if fail then assert
	% just some doc setup
	doc_clear,
	bump_tmp_directory_id,


	% add context information
	assert_object(time_period, Report_Period),

	#(HP..period = HP..repayment_period / HP..interest_period),
	#(HP..end_date = HP..begin_date + HP..hp_duration),
	#(Report_Period..end_date = Report_Period..end_date + Report_Period..duration),



	% add hp arrangement information
	assert_object(hp_arrangement,HP),

	% relate first installment to the list
	assert_object(hp_installment, Installment_1),

	% note the nonhomogeneous method of posing constraints
	doc(Installment_1, arrangement, HP),
	#(Installment_1..installment_number = 1), 
	#(Installment_1..opening_date = HP..begin_date + (HP..payment_type * HP..repayment_period)),
	#(Installment_1..opening_balance = HP..cash_price),
	#(Installment_1..installment_amount = HP..repayment_amount), % unless it's a balloon payment
	#(Installment_1..total_payments = Installment_1..installment_amount), % should be derived
	#(Installment_1..total_interest = Installment_1..interest_amount), % should be derived

	% generate the actual list / graph structure	
	Installments = [Installment_1 | Installments_Rest],
	gen_hp_installments(HP, Installment_1, Installments_Rest),
	last(Installments, Installment_N),

	% relate last installment to the list
	#(Installment_N..closing_date = HP..end_date), % should be derived? maybe not
	#(Installment_N..installment_number = HP..number_of_installments), % should be derived? yes; from statement that installment_number = list index and number_of_installments = list_length / cardinality; eliminate this by just querying directly for the list length in the document
	#(Installment_N..closing_balance = HP..final_balance), % should be derived?
	#(Installment_N..total_payments = HP..total_payments), % should be derived?
	#(Installment_N..total_interest = HP..total_interest), % should be derived?




	% (HP-)global constraints
	#(HP..total_payments = HP..cash_price + HP..total_interest - HP..final_balance),
	#(HP..liability_balance = HP..repayment_balance + HP..unexpired_interest),
	#(HP..repayment_balance = HP..current_liability + HP..noncurrent_liability),
	#(HP..unexpired_interest = HP..current_unexpired_interest + HP..noncurrent_unexpired_interest),

	% needs help in order to infer a repayment amount needed to pay off an arrangement in a given number of installments
	repayment_formula(HP),
	% context-dependent aggregate constraints
	% better way to write these constraints?
	% probably at least needs a higher-level way of talking about "current" vs. "noncurrent"
	% but it's already clunky anyway because we have to assert the constraints by looping over a list instead of
	% declaratively stating a relation between successive items
	%
	% also hard to simplify because it's necessarily parameterized, we're not gonna store the values for all combinations of
	% start and end dates..., but we are expecting to get the parameters in the documents defining the arrangement...,
	% so we can potentially just attach these values to the installments...
	/*
	this is just historical, current, and noncurrent on the transactions
	*/
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



	% should really be part of a bidirectional relationship between previous and next
	% add constraints between current and previous installment fields
	% all of this should be derived from a definition of lists, continuity, derivatives & integrals
	doc_add(Installment, previous, Previous_Installment), % continuity
	doc_add(Previous_Installment, next, Installment), % continuity
	#(Installment..opening_balance = Previous_Installment..closing_balance), % continuity
	#(Installment..opening_date = Previous_Installment..closing_date + 1),  % continuity
	#(Installment..installment_number = Previous_Installment..installment_number + 1), % integral dx
	#(Installment..total_interest = Previous_Installment..total_interest + Installment..interest_amount), % integral di
	#(Installment..total_payments = Previous_Installment..total_payments + HP..repayment_amount),         % integral dr



	#(Installment..closing_date = Installment..opening_date + HP..repayment_period - 1), % basic interval stuff


	#(Installment..installment_amount = HP..repayment_amount),
	#(Installment..interest_amount = Installment..opening_balance * HP..interest_rate * HP..period),
	#(Installment..closing_balance = Installment..opening_balance + Installment..interest_amount - HP..repayment_amount),
	% can represent this as an interest transaction and a repayment transaction into different subaccounts of the HP




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
	% sort of works if we mess with clpfd+clpq
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
	% termination analysis:
	% if Closing_Balance < Opening_Balance, then the arrangement would be payed off in a finite number of installments
	%  * max N such that P_N >= Final_Balance
	% if Closing_Balance >= Opening_Balance, then the arrangement would never be payed off

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
% needs to account for balloon payments
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
	#( A = ((P * ((1 + R * T)^N) - F) * R * T)/((1 + R * T)^N - 1) ).


/*
hp0 :-
	% add context information

	% this should be handled by dimensions
	%#(HP..period = HP..repayment_period / HP..interest_period),
	
	% this is a basic fact about time_periods
	%#(HP..end_date = HP..begin_date + HP..hp_duration),

	% this should be a separate document describing report period, historical, current, noncurrent, etc...
	
	%assert_object(time_period, Report_Period),
	%#(Report_Period..end_date = Report_Period..end_date + Report_Period..duration),
	


	% why are we asserting an hp_arrangement object?
	% add hp arrangement information
	assert_object(hp_arrangement,HP),

	% why are we asserting the existence of an installment?
	% we want to assert that there should be a series of transactions paying off the principal
	
	% relate first installment to the list
	assert_object(hp_installment, Installment_1),

	% note the nonhomogeneous method of posing constraints
	% doc(Installment_1, arrangement, HP), you can get this from the list it's contained in..
	% we only do this *if* the first installment actually exists
	#(Installment_1..installment_number = 1),
	#(Installment_1..opening_date = HP..begin_date + (HP..payment_type * HP..repayment_period)),
	#(Installment_1..opening_balance = HP..cash_price),

	% #(Installment_1..installment_amount = HP..repayment_amount), % unless it's a balloon payment

	% #(Installment_1..total_payments = Installment_1..installment_amount), % should be derived; just referencing the balance on payments
	% #(Installment_1..total_interest = Installment_1..interest_amount), % should be derived; just referencing the balance on interest

	% generate the actual list / graph structure	
	Installments = [Installment_1 | Installments_Rest],
	gen_hp_installments(HP, Installment_1, Installments_Rest),
	last(Installments, Installment_N),

	% relate last installment to the list
	#(Installment_N..closing_date = HP..end_date), % should be derived? maybe not
	% #(Installment_N..installment_number = HP..number_of_installments), % should be derived? yes; from statement that installment_number = list index and number_of_installments = list_length / cardinality; eliminate this by just querying directly for the list length in the document

	% #(Installment_N..closing_balance = HP..final_balance), % should be derived? should just reference the final installment closing balance directly
	% but then this also assumes there's always an installment; can always assume there's at least 1 installment of potentially 0 transfer...
	%#(Installment_N..total_payments = HP..total_payments), % should be derived? just referencing the balance on payments
	%#(Installment_N..total_interest = HP..total_interest), % should be derived? just referencing the balance on interest




	% (HP-)global constraints
	#(HP..total_payments = HP..cash_price + HP..total_interest - HP..final_balance),
	#(HP..liability_balance = HP..repayment_balance + HP..unexpired_interest),
	#(HP..repayment_balance = HP..current_liability + HP..noncurrent_liability),
	#(HP..unexpired_interest = HP..current_unexpired_interest + HP..noncurrent_unexpired_interest),

	% needs help in order to infer a repayment amount needed to pay off an arrangement in a given number of installments
	repayment_formula(HP),
	% context-dependent aggregate constraints
	% better way to write these constraints?
	% probably at least needs a higher-level way of talking about "current" vs. "noncurrent"
	% but it's already clunky anyway because we have to assert the constraints by looping over a list instead of
	% declaratively stating a relation between successive items
	%
	% also hard to simplify because it's necessarily parameterized, we're not gonna store the values for all combinations of
	% start and end dates..., but we are expecting to get the parameters in the documents defining the arrangement...,
	% so we can potentially just attach these values to the installments...
	/*
	this is just historical, current, and noncurrent on the transactions
	*/
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




*/

/*
hpi0(HP, Previous_Installment, [Installment | Rest]) :-
	% create current installment
	assert_object(hp_installment, Installment),


	% relate installment to hp arrangement and previous installment in graph
	%doc(Installment, arrangement, HP),



	% should really be part of a bidirectional relationship between previous and next
	% add constraints between current and previous installment fields
	% all of this should be derived from a definition of lists, continuity, derivatives & integrals
	%doc_add(Installment, previous, Previous_Installment), % continuity
	%doc_add(Previous_Installment, next, Installment), % continuity
	%#(Installment..opening_balance = Previous_Installment..closing_balance), % continuity
	%#(Installment..opening_date = Previous_Installment..closing_date + 1),  % continuity
	%#(Installment..installment_number = Previous_Installment..installment_number + 1), % integral dx
	%#(Installment..total_interest = Previous_Installment..total_interest + Installment..interest_amount), % integral di
	%#(Installment..total_payments = Previous_Installment..total_payments + HP..repayment_amount),         % integral dr



	%#(Installment..closing_date = Installment..opening_date + HP..repayment_period - 1), % basic interval stuff


	%#(Installment..installment_amount = HP..repayment_amount),
	Installment..transactions = [
		transaction(Interest_Account, Interest_Amount),
		transaction(Payment_Account, Payment_Amount)
	],
	%#(Installment..interest_amount = Installment..opening_balance * HP..interest_rate * HP..period),
	%#(Installment..closing_balance = Installment..opening_balance + Installment..interest_amount - HP..repayment_amount),
	% can represent this as an interest transaction and a repayment transaction into different subaccounts of the HP
	



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
	% sort of works if we mess with clpfd+clpq
	%{Repayment_Amount = (1 - Installment_Type)*HP_Repayment_Amount + Installment_Type*Balloon_Amount},
	%	* where Installment_Type in {0,1}
	




	% inequalities and bounds
	% can maybe be used eventually as part of termination analysis

	% closing_balance must be decreasing
	% should be that balance of installment transaction set should be negative
	#(Installment..closing_balance < Previous_Installment..closing_balance),

	% lower bounds on closing balance
	#(HP..final_balance =< Installment..closing_balance),

	% upper bounds on closing balances
	% {Previous_Opening_Balance < smallest principal for which the repayment amount would diverge},





	% and finally recurse to generate more installments unless we've generated all of them:
	% termination analysis:
	% if Closing_Balance < Opening_Balance, then the arrangement would be payed off in a finite number of installments
	%  * max N such that P_N >= Final_Balance
	% if Closing_Balance >= Opening_Balance, then the arrangement would never be payed off

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
*/
%


/*
	% relate first installment to the list
	assert_object(hp_installment, Installment_1),
	% assert in the sense that a bnode will be generated for it and graph triples for each field

	at any case, seems like we could later split this into the static/general data and the runtime-specific part:
	hp installment first_installment,
	first_installment 
		installment_number 1;
		opening_date 

	and then just say Installment_1 instanceOf hp_installment?
	on a second thought, if the same info is available from an actual request output, maybe there's no point?
*/


% balance on HP account should be a non-increasing curve connecting (start, principal) -> (end, final)
	% installment periods cover the interval [start,end]; 
	%	* associated intervals logic
	%	* limits logic to make coherent the concept of the balance being a continuous curve despite changing
	%	  in discrete steps; continuity in the sense that, at any boundary between two adjacent intervals
	%	  the value at the boundary is the same whichever interval it's measured in;
	%	* seems then that transactions would actually correspond to rate-like objects in the dimensional representation
	%	* advance/arrears is really part of more general thing about interval boundaries;
	%	* differential equations seem to be coming up as quite fundamental in some of the accounting equations, and just
	%	  the semantics of rate-like dimensions in general; the logic of limits is naturally associated with differential
	%	  equations in mathematics, so if the expressive utiltiy of differential equations can be exploited for practical
	%	  computational utility, then the logic of limits would likely be a critical component of the proper expression
	%	  of the logic of differential equations and their association with rate & interval-like dimensions. 

	% differential equations provide an extremely generic way to capture a lot of otherwise messy aspects of the HP logic...
	%	ex.. for a formulation
	%	  of interest-rates in terms of dimensional analysis, we want automatic handling of time & currency units, 
	%	  we say things like %/year, but this seems to translate to actual dimensions of currency/year for the interest payment amounts, 
	%	  and currency/year^2 dimensions on the rate of change of the interest payment amounts; this is a differential equation.
	%	  a system of differential equations, including this one and a similar one describing the regular repayment amounts, essentially
	%	  encapsulates all the logic surrounding the HP, and essentially allow for the statement of the logic to be nearly
	%	  reduced to a basic statement of the quantities, their dimensions, and their rates of change, and a surface layer can easily
	%	  translate the abused terminology of "%/year" or some such into that. it's natural that a differential equation
	%	  would be associated with the summations of course, since the summations are of course the corresponding integrals.
	%	  the dimensions of rates correspond naturally to the mathematics of differential equations.
	%
	%	 these patterns and associated differential equations should be expected to appear ubiquitiously throughout the accounting logic





% now needs to handle all the installments...
%  * even when it isn't given Number_Of_Installments or a complete list of installments
% relate Number_Of_Installments to the count of the installments
% insert & detect balloon payments; infer data even in the presence of balloon installments
% corrections
% if-then-else with CLP when the conditions might be variable ?
% handling units with CLP?
% handling date/time stuff with CLP?
% numeric stuff; limited-precision arithmetic relations; rounding
% * we have a basic way of dealing with the approximation errors while still allowing CLP(Q) to work
% proof-tracing
% document-oriented interface
