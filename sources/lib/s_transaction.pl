
% bank statement transaction record, these are in the input xml
s_transaction_fields([day, type_id, vector, account, exchanged, misc]).
% - The absolute day that the transaction happenned
% - The type identifier/action tag of the transaction
% - The amounts that are being moved in this transaction
% - The account that the transaction modifies without using exchange rate conversions
% - Either the units or the amount to which the transaction amount will be converted to, depending on whether the term is of the form bases(...) or vector(...).

doc_add_s_transaction(Day, Type_Id, Vector, Account_Id, Exchanged, Misc, Uri) :-
	doc_new_uri(st, Uri),
	doc_add(Uri, rdf:type, l:s_transaction, transactions),
	doc_add(Uri, s_transactions:day, Day, transactions),
	doc_add(Uri, s_transactions:type_id, Type_Id, transactions),
	doc_add(Uri, s_transactions:vector, Vector, transactions),
	doc_add(Uri, s_transactions:account, Account_Id, transactions),
	(	Exchanged = bases(B)
	->	(is_list(B) -> true ; throw(oops))
	;	(	Exchanged = vector(V)
		->	(
				assertion(is_list(V)),
				maplist(check_coord, V)
			)
		;	fail)),
	doc_add(Uri, s_transactions:exchanged, Exchanged, transactions),
	doc_add(Uri, s_transactions:misc, Misc, transactions).

check_coord(coord(U,A)) :-
	assertion((number(A);rational(A))),
	assertion((\+is_list(U),\+var(U))).

s_transaction_day(T, D) :-
	doc(T, s_transactions:day, D, transactions).
s_transaction_type_id(T, X) :-
	doc(T, s_transactions:type_id, X, transactions).
s_transaction_vector(T, X) :-
	doc(T, s_transactions:vector, X, transactions).
s_transaction_account(T, X) :-
	doc(T, s_transactions:account, X, transactions).
s_transaction_exchanged(T, X) :-
	doc(T, s_transactions:exchanged, X, transactions).
s_transaction_misc(T, X) :-
	doc(T, s_transactions:misc, X, transactions).
s_transaction_description2(T, X) :-
	doc(T, s_transactions:misc, M, transactions),
	X = M.get(desc2).
s_transaction_description3(T, X) :-
	doc(T, s_transactions:misc, M, transactions),
	X = M.get(desc3).

doc_set_s_transaction_field(Field, T0, X, T1, Op) :-
	s_transaction_fields(Fields),
	!member(Field, Fields),
	doc_set_property(s_transactions, T0, Fields, Field, X, transactions, T1, Op).


/* add a new object with P newly set to V, referencing the rest of Fields */
doc_set_property(Prefix, S1, Fields, P, V, G, S2, Op) :-
	doc_new_uri(S2),
	doc_new_uri(Relation),
	doc_add(Relation, l:has_subject, S1),
	doc_add(Relation, l:has_object, S2),
	doc_add(Relation, l:has_op, Op),
	(	doc(S1, rdf:type, Type, G)
	->	doc_add(S2, rdf:type, Type, G)),
	maplist(doc_set_property_helper(Prefix,S1,S2,P,V,G), Fields).

doc_set_property_helper(Prefix,S1,S2,P,V,G,Field) :-
	rdf_global_id(Prefix:P, Prop_Uri),
	rdf_global_id(Prefix:Field, Field_Uri),
	(	Prop_Uri == Field_Uri
	->	V2 = V
	;	doc(S1, Field_Uri, V2, G)),
	doc_add(S2, Field_Uri, V2, G).


 pretty_st_string(T, String) :-
	doc(T, rdf:type, l:s_transaction, transactions),
	s_transaction_day(T, Date),
	s_transaction_type_id(T, Action_verb),
	s_transaction_vector(T, Money),
	s_transaction_account(T, Account),
	s_transaction_exchanged(T, Exchanged),
	s_transaction_misc(T, Misc),
	format(
		string(String),
		's_transaction:~n  date:~q~n  verb:~w~n  vector: ~q~n  account: ~q~n  exchanged: ~q~n  misc: ~q',
		[
			Date,
			$>pretty_action_verb_term_string(Action_verb),
			$>round_term(Money),
			$>pretty_account_term_string(Account),
			$>round_term(Exchanged),
			Misc
		]
	).

pretty_account_term_string(uri(Account), Str) :-
	account_name(Account, Str).

pretty_account_term_string(bank_account_name(Account), Account).

pretty_account_term_string(account_name_ui_string(Account), Account).

pretty_action_verb_term_string(uri(Uri), Str) :-
	doc(Uri, l:has_id, Str),
	!.
pretty_action_verb_term_string(Str, Str).


 compare_s_transactions(Order, T1, T2) :-
	/* warning: Order must never be =, this would remove one of the transactions as duplicates */
	ground(T1), ground(T2),
	s_transaction_day(T1, Day1),
	s_transaction_day(T2, Day2),
	compare(Order0, Day1, Day2),
	(	Order0 \= '='
	->	Order = Order0
	;	(
	/* If a buy and a sale of same thing happens on the same day, we want to process the buy first. */
	s_transaction_vector(T1, [coord(_, Debit1)]),
	s_transaction_vector(T2, [coord(_, Debit2)]),
	compare(Order1, Debit1, Debit2),
	(	Order1 \= '='
	->	Order = Order1
	;
	/* if all else fails, sort by uri, which is unique, thus, every tx is preserved */
	compare(Order, T1, T2)))).


sort_s_transactions(In, Out) :-
	predsort(compare_s_transactions, In, Out).


s_transactions_up_to(End_Date, S_Transactions_All, S_Transactions_Capped) :-
	findall(
		T,
		(
			member(T, S_Transactions_All),
			s_transaction_day(T, D),
			D @=< End_Date
		),
		S_Transactions_Capped
	).


 s_transaction_to_dict(T, D) :-
	doc(T, rdf:type, l:s_transaction, transactions),
	s_transaction_day(T, Day),
	s_transaction_type_id(T, uri(Action_Verb)),
	s_transaction_vector(T, Vector),
	!s_transaction_account(T, uri(Account)),
	account_name(Account, Account_name),
	s_transaction_exchanged(T, Exchanged),
	s_transaction_misc(T, Misc),
	(	/* here's an example of the shortcoming of ignoring the rdf prefix issue, fixme */
		doc(Action_Verb, l:has_id, Verb_Label)
	->	true
	;	Verb_Label = Action_Verb),
	D0 = _{
		date: Day,
		verb: Verb_Label,
		vector: Vector,
		account: Account,
		account_name: Account_name,
		exchanged: Exchanged,
		misc: Misc},
	st_stuff1(T, D0, D).


 st_stuff1(T, Dict, Dict_out) :-
	doc(T, l:has_tb, Tb0),
	term_string($>round_term(Tb0),Tb_str),
	findall(Alert,doc(T, l:has_alert, Alert),Alerts),
	term_string($>round_term(Alerts), Alerts_str),
	Dict_out = Dict.put(note, Alerts_str).put(tb, Tb_str).



 'pre-preprocess source transactions'(In, Out) :-
	/*
	at this point:
	s_transactions are sorted by date from oldest to newest
	bank s_transactions have flipped vectors, so they are from our perspective
	primary accounts are specified with bank_account_name() or account_name_ui_string() or maybe uri()
	*/
	maplist(prepreprocess_s_transaction0, In, Out).

 prepreprocess_s_transaction0(In, Out) :-
 	pretty_st_string(In, Sts),
	push_format('pre-pre-processing source transaction:~n ~w', [Sts]),
	prepreprocess_s_transaction(In, Out),
	pop_context.

 prepreprocess_s_transaction(In, Out) :-
	cf(infer_exchanged_units_count(In, Mid)),
	!,
	cf(prepreprocess_s_transaction(Mid, Out)).

/* add livestock verb uri */
 prepreprocess_s_transaction(In, Out) :-
	cf(infer_livestock_action_verb(In, Mid)),
	!,
	prepreprocess_s_transaction(Mid, Out).

/* from verb label to verb uri */
prepreprocess_s_transaction(S_Transaction, Out) :-
	s_transaction_action_verb_uri_from_string(S_Transaction, Action_Verb),
	!,
	doc_set_s_transaction_field(type_id,S_Transaction, uri(Action_Verb), NS_Transaction, action_verb_uri_from_string),
	prepreprocess_s_transaction(NS_Transaction, Out).

/* from first account term to uri() */
prepreprocess_s_transaction(In, Out) :-
	's_transaction first account term to uri'(In, First_account_uri),
	!,
	doc_set_s_transaction_field(account,In, uri(First_account_uri), NS_Transaction, 's_transaction first account term to uri'),
	prepreprocess_s_transaction(NS_Transaction, Out).

prepreprocess_s_transaction(T, T) :-
	s_transaction_account(T, A),
	assertion(A = uri(_)),
	s_transaction_type_id(T, B),
	assertion(B = uri(_)).

's_transaction first account term to uri'(St, Gl_account) :-
	s_transaction_account(St, A),
	A = bank_account_name(N),
	abrlt('Banks'/N, Gl_account),
	!.

's_transaction first account term to uri'(St, Gl_account) :-
	s_transaction_account(St, A),
	A = account_name_ui_string(N0),
	!atom_string(N, N0),
	!account_by_ui(N, Gl_account),
	!.


% This Prolog rule handles the case when only the exchanged units are known (for example GOOG)  and
% hence it is desired for the program to infer the count.
 infer_exchanged_units_count(S_Transaction, NS_Transaction) :-
	s_transaction_exchanged(S_Transaction, bases(Goods_Bases)),
	s_transaction_day(S_Transaction, Transaction_Date),
	s_transaction_vector(S_Transaction, Vector),
	% infer the count by money debit/credit and exchange rate
	%gtrace,
	result_property(l:exchange_rates_even_at_cost, Exchange_Rates),
	vec_change_bases_throw(Exchange_Rates, Transaction_Date, Goods_Bases, Vector, Vector_Exchanged),
	vec_inverse(Vector_Exchanged, Vector_Exchanged_Inverted),
	doc_set_s_transaction_field(exchanged, S_Transaction, vector(Vector_Exchanged_Inverted), NS_Transaction, infer_exchanged_units_count).

/* used on raw s_transaction during prepreprocessing */
 s_transaction_action_verb_uri_from_string(S_Transaction, Action_Verb) :-
	s_transaction_type_id(S_Transaction, Type_Id),
	Type_Id \= uri(_),
	(	(
			action_verb(Action_Verb),
			doc(Action_Verb, l:has_id, Type_Id)
		)
	->	true
	;	(throw_string(['action verb not found by id: "',Type_Id,'"']))).

 extract_exchanged_value(Tx_dom, Bank_dr, Exchanged) :-
	(	field_nothrow(Tx_dom, [unitType, Unit_type])
	->	true
	;	Unit_type = nil(nil)),

	(	field_nothrow(Tx_dom, [unit, Unit_count_atom])
	->	(	atom_number(Unit_count_atom, Unit_count0),
			(	Unit_count0 = 0
			->	Unit_count = nil(nil)
			;	Unit_count = Unit_count0))
	;	Unit_count = nil(nil)),

	(	Bank_dr < 0
	->	Money_side = kb:debit
	;	Money_side = kb:credit),

	extract_exchanged_value2(Money_side, Unit_type, Unit_count, Exchanged).

 extract_exchanged_value2(Money_side, Unit_type, Unit_count, Exchanged) :-
	(	Unit_type = nil(nil)
	->	(	Unit_count = nil(nil)
		->	Exchanged = vector([])
		;	throw_string('unit count specified, but unit type missing'))
	;	(	Unit_count = nil(nil)
		->	% If the user has specified only a unit type, then infer count by exchange rate
			(
				Exchanged = bases([Unit_type])
			)
		;	(
				Count_absolute is rationalize(abs(Unit_count)),
				(	Money_side = kb:credit
				->	Exchanged = vector([coord(Unit_type, Count_absolute)])
				;	(
						Count_credit is -Count_absolute,
						Exchanged = vector([coord(Unit_type, Count_credit)])
					)
				)
			)
		)
	).


 invert_s_transaction_vector(T0, T1) :-
	!s_transaction_vector(T0, Vector),
	!vec_inverse(Vector, Vector_Inverted),
	!doc_set_s_transaction_field(vector,T0, Vector_Inverted, T1, invert_s_transaction_vector).



 handle_additional_files(S_Transactions) :-
	(	(
			true,
			value($>get_optional_singleton_sheet_data(ic_ui:additional_files_sheet), Files)
		)
	->	(
			maplist(handle_additional_file, $> doc_list_items(Files), S_Transactions0),
			flatten(S_Transactions0, S_Transactions)
		)
	;	S_Transactions = []).

handle_additional_file(Bn, S_Transactions) :-
	(	extract_german_bank_csv0(Bn, S_Transactions)
	->	true
	;	throw_string(['unrecognized file format (', Bn, ')'])).







 collect_sources_set(Txs, Sources, Txs_by_sources) :-
	findall(
		(Source, Tx),
		(
			member(Tx, Txs),
			assertion(nonvar(Tx)),
			doc(Tx, transactions:origin, Source, transactions),
			assertion(nonvar(Source))
		),
		Pairs0),
	maplist([(St, Tx), St]>>true, Pairs0, Sources0),
	list_to_set(Sources0, Sources),
	!sort_into_dict2([(St, Tx), St, Tx]>>true, Pairs0, Txs_by_sources).

