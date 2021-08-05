%:- use_module(library(chr), [enumerate_constraints/1]).


chase_kb(N/*, Done*/) :-
	format(user_error, "Starting chase(~w)~n", [N]),
	start(N, _).
	

doc_get_attribute(S, P, O) :- (doc_value(S, P, O) -> true ; true).

hp_doc_to_chr_basic :-
	debug(hp_doc_to_chr_basic),

	debug(hp_doc_to_chr_basic, "retrieving doc facts:...~n", []),
	?get_optional_singleton_sheet_data(hp_ui:hp_calculator_query, HP_Calculator_Query),
	%docm(HP_Calculator_Query,rdf:type,hp:hp_calculator_query),
	doc_get_attribute(HP_Calculator_Query,hp:begin_date, HP_Begin_Date),
	debug(hp_doc_to_chr_basic, "retrieved doc date: ~w~n", [HP_Begin_Date]),

	docm(HP_Calculator_Query,hp:hp_contract, HP_Contract),
	docm(HP_Contract, rdf:type, hp:hp_contract),
	doc_get_attribute(HP_Contract, hp:cash_price, HP_Cash_Price),
	doc_get_attribute(HP_Contract, hp:contract_number, HP_Contract_Number),
	doc_get_attribute(HP_Contract, hp:currency, HP_Currency),
	doc_get_attribute(HP_Contract, hp:hp_contract_has_payment_type, HP_Contract_Has_Payment_Type),
	doc_get_attribute(HP_Contract, hp:hp_installments, HP_Installments),
	doc_get_attribute(HP_Contract, hp:interest_rate, HP_Interest_Rate),
	doc_get_attribute(HP_Contract, hp:number_of_installments, HP_Number_of_Installments),
	doc_get_attribute(HP_Contract, hp:repayment_amount, HP_Repayment_Amount),
	doc_get_attribute(HP_Contract, hp:final_balance, HP_Final_Balance),
	hp_installments_to_chr_basic(HP_Installments, CHR_HP_Installments, Installments_Facts),


	debug(hp_doc_to_chr_basic, "inserting chr facts:...~n", []),
	fact(CHR_HP_Contract, a, hp_arrangement),

	fact(CHR_HP_Contract, begin_date, CHR_HP_Begin_Date),
	debug(hp_doc_to_chr_basic, "doc_date_to_chr_facts(~w, ~w),~n", [CHR_HP_Begin_Date, HP_Begin_Date]),
	doc_date_to_chr_facts(CHR_HP_Begin_Date, HP_Begin_Date),
	debug(hp_doc_to_chr_basic, "done inserting chr date facts:...~n", []),

	fact(CHR_HP_Contract, cash_price, HP_Cash_Price),

	fact(CHR_HP_Contract, contract_number, HP_Contract_Number),

	fact(CHR_HP_Contract, currency, HP_Currency),

	fact(CHR_HP_Contract, payment_type, HP_Contract_Has_Payment_Type),

	fact(CHR_HP_Contract, installments, CHR_HP_Installments),
	maplist([fact(S,P,O)]>>fact(S,P,O), Installments_Facts),

	fact(CHR_HP_Contract, interest_rate, HP_Interest_Rate),

	fact(CHR_HP_Contract, number_of_installments, HP_Number_of_Installments),

	fact(CHR_HP_Contract, repayment_amount, HP_Repayment_Amount),

	fact(CHR_HP_Contract, final_balance, HP_Final_Balance),

	debug(hp_doc_to_chr_basic, "done inserting chr facts:...~n", []),

	dump_chr.

% what to do in case of variable HP_Installments?
hp_installments_to_chr_basic(rdf:nil, _, []) :- !.
hp_installments_to_chr_basic(HP_Installments, _, []) :- var(HP_Installments), !.
hp_installments_to_chr_basic(HP_Installments, _, []) :- \+doc(HP_Installments, rdf:first, _).
hp_installments_to_chr_basic(HP_Installments, CHR_HP_Installments, [fact(CHR_HP_Installments, first, HP_Installments) | Installment_Facts]) :-
	doc(HP_Installments, rdf:first, _),
	hp_installments_to_chr_basic_helper(HP_Installments, Installment_Facts).

hp_installments_to_chr_basic_helper(rdf:nil, []).
hp_installments_to_chr_basic_helper(Current_Item, Facts) :-
	(
		doc(Current_Item, rdf:first, Value)
	->	Facts = [fact(Current_Item, value, Value) | Rest_Facts]
	;	Facts = Rest_Facts
	),
	(
		doc(Current_Item, rdf:rest, Rest_List)
	->	Rest_Facts = [fact(Current_Item, next, Rest_List) | Rest_Rest_Facts],
		hp_installments_to_chr_basic_helper(Rest_List, Rest_Rest_Facts)
	;	Rest_Facts = []
	).

doc_date_to_chr_facts(CHR_Date, Doc_Date) :-
	Doc_Date = Date_Part^^_,
	(
		Date_Part = date_time(Year, Month, Day, Hour, Minute, Second)
	->	fact(CHR_Date, year, Year),
		fact(CHR_Date, month, Month),
		fact(CHR_Date, day, Day),
		fact(CHR_Date, hour, Hour),
		fact(CHR_Date, minute, Minute),
		fact(CHR_Date, second, Second)
	;	% unknown date format, don't translate.
		true
	).
doc_date_to_chr_facts(CHR_Date, Doc_Date) :-
	Doc_Date = date(Year, Month, Day),
	fact(CHR_Date, year, Year),
	fact(CHR_Date, month, Month),
	fact(CHR_Date, day, Day).

doc_date_to_chr_facts(CHR_Date, Doc_Date) :-
	Doc_Date = date_time(Year, Month, Day, Hour, Minute, Second),
	fact(CHR_Date, year, Year),
	fact(CHR_Date, month, Month),
	fact(CHR_Date, day, Day),
	fact(CHR_Date, hour, Hour),
	fact(CHR_Date, minute, Minute),
	fact(CHR_Date, second, Second).

dump_chr :-
	format(user_error,"dump_chr:~n",[]),
	findall(
		_,
		(
			'$enumerate_constraints'(fact(S,P,O)),
			maplist(rat_to_float, [S,P,O], [S1,P1,O1]),
			format(user_error,"~w ~w ~w~n", [S1,P1,O1])
		),
		_
	),
	nl.

rat_to_float(R, R) :- \+rational(R).
rat_to_float(R, R) :- rational(R), integer(R).
rat_to_float(R, F) :- rational(R), \+integer(R), F is float(R).


hp_doc_from_chr_basic :-
	%debug(hp_doc_from_chr_basic),
	debug(hp_chr_installments_to_doc_basic),
	%debug(chr_date_to_doc_facts),
	%debug(chr_get_attribute),
	debug(hp_doc_from_chr_basic, "hp_doc_from_chr_basic: retrieving chr facts...~n", []),
	find_fact3(CHR_HP_Contract1, a, hp_arrangement, [], Subs0),
	get_sub(CHR_HP_Contract1, Subs0, HP_Contract),

	find_fact3(CHR_HP_Contract1, begin_date, CHR_HP_Begin_Date1, Subs0, Subs1),
	get_sub(CHR_HP_Begin_Date1, Subs1, CHR_HP_Begin_Date),

	find_fact3(CHR_HP_Contract1, cash_price, HP_Cash_Price1, Subs1, Subs2),
	get_sub(HP_Cash_Price1, Subs2, HP_Cash_Price),

	find_fact3(CHR_HP_Contract1, contract_number, HP_Contract_Number1, Subs2, Subs3),
	get_sub(HP_Contract_Number1, Subs3, HP_Contract_Number),

	find_fact3(CHR_HP_Contract1, currency, HP_Currency1, Subs3, Subs4),
	get_sub(HP_Currency1, Subs4, HP_Currency),

	find_fact3(CHR_HP_Contract1, payment_type, HP_Contract_Has_Payment_Type1, Subs4, Subs5),
	get_sub(HP_Contract_Has_Payment_Type1, Subs5, HP_Contract_Has_Payment_Type),

	find_fact3(CHR_HP_Contract1, installments, CHR_HP_Installments1, Subs5, Subs6),
	get_sub(CHR_HP_Installments1, Subs6, CHR_HP_Installments),

	find_fact3(CHR_HP_Contract1, interest_rate, HP_Interest_Rate1, Subs6, Subs7),
	get_sub(HP_Interest_Rate1, Subs7, HP_Interest_Rate),

	find_fact3(CHR_HP_Contract1, number_of_installments, HP_Number_of_Installments1, Subs7, Subs8),
	get_sub(HP_Number_of_Installments1, Subs8, HP_Number_of_Installments),

	find_fact3(CHR_HP_Contract1, repayment_amount, HP_Repayment_Amount1, Subs8, Subs9),
	get_sub(HP_Repayment_Amount1, Subs9, HP_Repayment_Amount),

	find_fact3(CHR_HP_Contract1, final_balance, HP_Final_Balance1, Subs9, Subs10),
	get_sub(HP_Final_Balance1, Subs10, HP_Final_Balance),

	debug(hp_doc_from_chr_basic, "hp_doc_from_chr_facts: adding doc facts...~n", []),
	doc_add_safe(l:response,hp_ui:hp_calculator_query,HP_Calculator_Query),
	doc_add_safe(HP_Calculator_Query,rdf:type,hp:hp_calculator_query),
	doc_add_safe(HP_Calculator_Query,hp:begin_date, HP_Begin_Date),
	chr_date_to_doc_facts(CHR_HP_Begin_Date, HP_Begin_Date),
	doc_add_safe(HP_Calculator_Query,hp:hp_contract, HP_Contract),
	doc_add_safe(HP_Contract, rdf:type, hp:hp_contract),
	doc_add_value_safe(HP_Contract, hp:cash_price, HP_Cash_Price),
	doc_add_value_safe(HP_Contract, hp:contract_number, HP_Contract_Number),
	doc_add_value_safe(HP_Contract, hp:currency, HP_Currency),
	doc_add_value_safe(HP_Contract, hp:hp_contract_has_payment_type, HP_Contract_Has_Payment_Type),
	doc_add_value_safe(HP_Contract, hp:interest_rate, HP_Interest_Rate),
	doc_add_value_safe(HP_Contract, hp:number_of_installments, HP_Number_of_Installments),
	doc_add_value_safe(HP_Contract, hp:repayment_amount, HP_Repayment_Amount),
	doc_add_value_safe(HP_Contract, hp:final_balance, HP_Final_Balance),

	debug(hp_doc_from_chr_basic, "hp_doc_from_chr_basic: added everything but installments...~n", []),
	doc_add_value_safe(HP_Contract, hp:hp_installments, HP_Installments),
	find_fact3(CHR_HP_Installments1, first, X, [CHR_HP_Installments1:CHR_HP_Installments], Subs_Test),
	get_sub(X, Subs_Test, X_Value),
	X_Value = HP_Installments,
	debug(hp_doc_from_chr_basic, "hp_doc_from_chr_basic: installments: ~w first ~w~n", [CHR_HP_Installments, X_Value]),
	debug(hp_doc_from_chr_basic, "calling:hp_chr_installments_to_doc_basic(~w, ~w)~n", [CHR_HP_Installments, HP_Installments]),
	hp_chr_installments_to_doc_basic(CHR_HP_Installments, HP_Installments),
	debug(hp_doc_from_chr_basic, "hp_doc_from_chr_facts: done adding doc facts...~n", []).

chr_date_to_doc_facts(CHR_Date, Doc_Date) :-
	debug(chr_date_to_doc_facts, "chr_date_to_doc_facts(~w,~w)~n", [CHR_Date, Doc_Date]),
	chr_get_attribute(CHR_Date, year, Year),
	chr_get_attribute(CHR_Date, month, Month),
	chr_get_attribute(CHR_Date, day, Day),
	chr_get_attribute(CHR_Date, hour, Hour),
	chr_get_attribute(CHR_Date, minute, Minute),
	chr_get_attribute(CHR_Date, second, Second),
	maplist(chr_var_to_doc_bnode, [Year, Month, Day, Hour, Minute, Second], [Year1, Month1, Day1, Hour1, Minute1, Second1]),
	doc_add_safe(Doc_Date, rdf:value, date_time(Year1, Month1, Day1, Hour1, Minute1, Second1)^^'http://www.w3.org/2001/XMLSchema#dateTime').

doc_add_safe(S1,P1,O1) :-
	maplist(chr_term_to_doc_term, [S1,P1,O1], [S2,P2,O2]),
	(
		\+docm(S2,P2,O2)
	->	maplist(chr_var_to_doc_bnode, [S2,P2,O2], [S,P,O]),
		doc_add(S,P,O)
	;	doc(S2,P2,O2)
	).

doc_add_value_safe(S1,P1,O1) :-
	maplist(chr_term_to_doc_term, [S1,P1,O1], [S,P,O]),
	(
		\+docm(S,P,_)
	->	doc_new_uri(URI),
		doc_add_safe(S,P,URI),
		doc_add_safe(URI, rdf:value, O)
	;	doc(S,P,X),
		doc_add_safe(X, rdf:value, O)
	).
	
chr_term_to_doc_term(Term, Term) :- 
	nonvar(Term),
	Term \= _:_.

chr_term_to_doc_term(Term, Doc_Term) :-
	nonvar(Term),
	Term = Prefix:Suffix,
	doc_prefix(Prefix,RDF_Prefix),
	atom_concat(RDF_Prefix,Suffix, Doc_Term).

chr_term_to_doc_term(Term, Term) :- 
	var(Term).

chr_var_to_doc_bnode(Term, Term) :- nonvar(Term).
chr_var_to_doc_bnode(Var, Bnode) :- var(Var), doc_new_uri(Bnode), Var = Bnode.

hp_chr_installments_to_doc_basic(CHR_HP_Installments, _) :-
	debug(hp_chr_installments_to_doc_basic, "hp_chr_installments_to_doc_basic: case 1...~n", []),
	\+find_fact2(CHR_HP_Installments1, first, _, [CHR_HP_Installments1:CHR_HP_Installments]),
	debug(hp_chr_installments_to_doc_basic, "hp_chr_installments_to_doc_basic: case 1 success~n", []),
	!.

hp_chr_installments_to_doc_basic(CHR_HP_Installments, HP_Installments) :-
	debug(hp_chr_installments_to_doc_basic, "hp_chr_installments_to_doc_basic: case 2...~n", []),
	find_fact2(CHR_HP_Installments1, first, HP_Installments, [CHR_HP_Installments1:CHR_HP_Installments]),
	debug(hp_chr_installments_to_doc_basic, "hp_chr_installments_to_doc_basic: case 2 success~n", []),
	hp_chr_installments_to_doc_basic_helper(HP_Installments).

hp_chr_installments_to_doc_basic_helper(Current_Item) :-
	format(user_error, "hp_chr_installments_to_doc_basic_helper(~w)~n", [Current_Item]),
	(
		find_fact3(Current_Item1, value, Value, [Current_Item1:Current_Item], Subs)
	->	get_sub(Value, Subs, Installment),
		doc_add_safe(Current_Item, rdf:first, Installment),
		hp_chr_installment_to_doc_basic(Installment)
	;	true
	),
	(
		find_fact3(Current_Item1, next, Next_Item, [Current_Item1:Current_Item], Subs2)
	->	
		get_sub(Next_Item, Subs2, Next_Item_Actual),
		format(user_error, "~w has next item ~w~n", [Current_Item, Next_Item_Actual]), 
		doc_add_safe(Current_Item, rdf:rest, Next_Item_Actual),
		hp_chr_installments_to_doc_basic_helper(Next_Item_Actual)
	;	format(user_error, "~w has no next item.~n", [Current_Item])
	).

hp_chr_installment_to_doc_basic(Installment) :-
	%debug(hp_chr_installment_to_doc_basic),
	debug(hp_chr_installment_to_doc_basic, "hp_chr_installment_to_doc_basic: retrieve chr facts...~n", []),
	find_fact3(Installment1, opening_date, Opening_Date1, [Installment1:Installment], Subs1),
	get_sub(Opening_Date1, Subs1, Opening_Date),

	find_fact3(Installment1, opening_balance, Opening_Balance1, [Installment1:Installment], Subs2),
	get_sub(Opening_Balance1, Subs2, Opening_Balance),

	find_fact3(Installment1, closing_date, Closing_Date1, [Installment1:Installment], Subs3),
	get_sub(Closing_Date1, Subs3, Closing_Date),
	
	find_fact3(Installment1, closing_balance, Closing_Balance1, [Installment1:Installment], Subs4),
	get_sub(Closing_Balance1, Subs4, Closing_Balance),

	find_fact3(Installment1, payment_amount, Payment_Amount1, [Installment1:Installment], Subs5),
	get_sub(Payment_Amount1, Subs5, Payment_Amount),

	find_fact3(Installment1, interest_rate, Interest_Rate1, [Installment1:Installment], Subs6),
	get_sub(Interest_Rate1, Subs6, Interest_Rate),

	find_fact3(Installment1, interest_amount, Interest_Amount1, [Installment1:Installment], Subs7),
	get_sub(Interest_Amount1, Subs7, Interest_Amount),


	debug(hp_chr_installment_to_doc_basic, "hp_chr_installment_to_doc_basic: put doc facts...~n", []),

	debug(hp_chr_installment_to_doc_basic, "hp_chr_installment_to_doc_basic: opening date...~n", []),
	doc_add_safe(Installment, hp_installment:opening_date, Opening_Date2),
	
	debug(hp_chr_installment_to_doc_basic, "hp_chr_installment_to_doc_basic: opening date... chr_date_to_doc_facts(~w, ~w)~n", [Opening_Date, Opening_Date2]),
	chr_date_to_doc_facts(Opening_Date, Opening_Date2),

	debug(hp_chr_installment_to_doc_basic, "hp_chr_installment_to_doc_basic: opening balance...~n", []),
	doc_add_value_safe(Installment, hp_installment:opening_balance, Opening_Balance),

	debug(hp_chr_installment_to_doc_basic, "hp_chr_installment_to_doc_basic: closing date...~n", []),
	doc_add_safe(Installment, hp_installment:closing_date, Closing_Date2),
	chr_date_to_doc_facts(Closing_Date, Closing_Date2),

	debug(hp_chr_installment_to_doc_basic, "hp_chr_installment_to_doc_basic: closing balance...~n", []),
	doc_add_value_safe(Installment, hp_installment:closing_balance, Closing_Balance),
	doc_add_value_safe(Installment, hp_installment:payment_amount, Payment_Amount),
	doc_add_value_safe(Installment, hp_installment:interest_rate, Interest_Rate),
	doc_add_value_safe(Installment, hp_installment:interest_amount, Interest_Amount),

	debug(hp_chr_installment_to_doc_basic, "hp_chr_installment_to_doc_basic: done...~n", []).


chr_get_attribute(S,P,O) :-
	debug(chr_get_attribute, "chr_get_attribute(~w,~w,~w)~n", [S,P,O]),
	(
		find_fact3(S1,P,O,[S1:S], Subs)
	->	debug(chr_get_attribute, "chr_get_attribute: found attribute, subs=~w~n", [Subs]),
		get_sub(O, Subs, O_Value),
		O = O_Value
	; 	debug(chr_get_attribute, "chr_get_attribute: no attribute...~n", []),
		true
	).

dump_doc(Label) :-
	format(user_error, "dump_doc: ~w~n", [Label]),
	findall(
		_,
		(
			docm(S,P,O),
			maplist(rat_to_float, [S,P,O], [S1,P1,O1]),
			format(user_error, "~w ~w ~w~n", [S1,P1,O1])
		),
		_
	),
	nl.

get_sub(Var, [K:V | Rest], Sub) :-
	(
		Var == K
	->	Sub = V
	;	get_sub(Var, Rest, Sub)
	).

doc_prefix(code, 'https://rdf.lodgeit.net.au/v1/code#').
doc_prefix(l, 'https://rdf.lodgeit.net.au/v1/request#').
doc_prefix(livestock, 'https://rdf.lodgeit.net.au/v1/livestock#').
doc_prefix(excel, 'https://rdf.lodgeit.net.au/v1/excel#').
doc_prefix(depr, 'https://rdf.lodgeit.net.au/v1/calcs/depr#').
doc_prefix(ic, 'https://rdf.lodgeit.net.au/v1/calcs/ic#').
doc_prefix(hp, 'https://rdf.lodgeit.net.au/v1/calcs/hp#').
doc_prefix(hp_ui, 'https://rdf.lodgeit.net.au/v1/calcs/hp/ui#').
doc_prefix(hp_installment, 'https://rdf.lodgeit.net.au/v1/calcs/hp/installment#').
doc_prefix(depr_ui, 'https://rdf.lodgeit.net.au/v1/calcs/depr/ui#').
doc_prefix(ic_ui, 'https://rdf.lodgeit.net.au/v1/calcs/ic/ui#').
doc_prefix(transactions, 'https://rdf.lodgeit.net.au/v1/transactions#').
doc_prefix(s_transactions, 'https://rdf.lodgeit.net.au/v1/s_transactions#').
doc_prefix(rdf, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').
doc_prefix(rdfs, 'http://www.w3.org/2000/01/rdf-schema#').
doc_prefix(xml, 'http://www.w3.org/XML/1998/namespace#').
doc_prefix(xsd, 'http://www.w3.org/2001/XMLSchema#').


print_chr_hp_facts :-
	format(user_error, "~n~n", []),
	findall(
		_,
		(
			'$enumerate_constraints'(fact(HP, a, hp_arrangement)),
			print_chr_hp_facts(HP)
		),
		_
	),
	format(user_error, "~n", []).

print_chr_hp_facts(HP) :-
	format(user_error, "Printing HP facts for: ~w~n", [HP]),

	chr_get_attribute(HP, begin_date, Begin_Date),
	chr_date_to_term(Begin_Date, Begin_Date_Term),
	format(user_error, "Begin date: ~w~n", [Begin_Date_Term]),

	chr_get_attribute(HP, end_date, End_Date),
	chr_date_to_term(End_Date, End_Date_Term),
	format(user_error, "End date: ~w~n", [End_Date_Term]),

	chr_get_attribute(HP, cash_price, Cash_Price),
	rat_to_float(Cash_Price, Cash_Price_Float),
	format(user_error, "Cash price: ~w~n", [Cash_Price_Float]),

	chr_get_attribute(HP, interest_rate, Interest_Rate),
	rat_to_float(Interest_Rate, Interest_Rate_Float),
	format(user_error, "Interest rate: ~w~n", [Interest_Rate_Float]),

	chr_get_attribute(HP, repayment_amount, Repayment_Amount),
	rat_to_float(Repayment_Amount, Repayment_Amount_Float),
	format(user_error, "Repayment amount: ~w~n", [Repayment_Amount_Float]),

	chr_get_attribute(HP, final_balance, Final_Balance),
	rat_to_float(Final_Balance, Final_Balance_Float),
	format(user_error, "Final balance: ~w~n", [Final_Balance_Float]),

	chr_get_attribute(HP, number_of_installments, Number_Of_Installments),
	format(user_error, "Number of installments: ~w~n", [Number_Of_Installments]),


	chr_get_attribute(HP, installments, Installments),
	print_chr_installments(Installments),

	format(user_error, "~n", []).

print_chr_installments(Installments) :-
	find_fact3(Installments1, first, First_Installment_Cell1, [Installments1:Installments], Subs),
	get_sub(First_Installment_Cell1, Subs, First_Installment_Cell),
	print_chr_installments_helper(First_Installment_Cell, 1).

print_chr_installments_helper(Cell, N) :-
	format(user_error, "~n", []),
	format(user_error, "Installment ~w: ~w~n", [N, Cell]),


	find_fact3(Cell1, value, Installment1, [Cell1:Cell], Subs),
	get_sub(Installment1, Subs, Installment),

	print_chr_installment(Installment),
	(
		find_fact3(Cell1, next, Next_Cell1, [Cell1:Cell], Subs2)
	->	get_sub(Next_Cell1, Subs2, Next_Cell),
		M is N + 1,
		print_chr_installments_helper(Next_Cell, M)
	;	true
	).

print_chr_installment(Installment) :-
	chr_get_attribute(Installment, opening_date, Opening_Date),
	chr_date_to_term(Opening_Date, Opening_Date_Term),
	format(user_error, "Opening_Date: ~w~n", [Opening_Date_Term]),

	chr_get_attribute(Installment, opening_balance, Opening_Balance),
	rat_to_float(Opening_Balance, Opening_Balance_Float),
	format(user_error, "Opening balance: ~w~n", [Opening_Balance_Float]),

	chr_get_attribute(Installment, interest_amount, Interest_Amount),
	rat_to_float(Interest_Amount, Interest_Amount_Float),
	format(user_error, "Interest amount: ~w~n", [Interest_Amount_Float]),

	chr_get_attribute(Installment, payment_amount, Payment_Amount),
	rat_to_float(Payment_Amount, Payment_Amount_Float),
	format(user_error, "Payment amount: ~w~n", [Payment_Amount_Float]),

	chr_get_attribute(Installment, closing_date, Closing_Date),
	chr_date_to_term(Closing_Date, Closing_Date_Term),
	format(user_error, "Closing date: ~w~n", [Closing_Date_Term]),

	chr_get_attribute(Installment, closing_balance, Closing_Balance),
	rat_to_float(Closing_Balance, Closing_Balance_Float),
	format(user_error, "Closing balance: ~w~n", [Closing_Balance_Float]).

chr_date_to_term(Date, date(Year, Month, Day)) :-
	chr_get_attribute(Date, year, Year),
	chr_get_attribute(Date, month, Month),
	chr_get_attribute(Date, day, Day).

process_request_hirepurchase_new :-
	%dump_doc("Before"),
	debug(hp_main),
	debug(hp_main, "hp_doc_to_chr_basic,~n", []),
	hp_doc_to_chr_basic,
	debug(hp_main, "chase_kb(20),~n", []),
	chase_kb(40),
	print_chr_hp_facts,
	debug(hp_main, "hp_doc_from_chr_basic,~n", []),
	hp_doc_from_chr_basic,
	debug(hp_main, "dump_doc(\"After\").~n", []),
	dump_doc("After").
