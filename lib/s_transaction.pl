:- use_module(library(dcg/basics)).

% bank statement transaction record, these are in the input xml
s_transaction_fields([day, type_id, vector, account, exchanged, misc]).
% - The absolute day that the transaction happenned
% - The type identifier/action tag of the transaction
% - The amounts that are being moved in this transaction
% - The account that the transaction modifies without using exchange rate conversions
% - Either the units or the amount to which the transaction amount will be converted to, depending on whether the term is of the form bases(...) or vector(...).

doc_add_s_transaction(Day, Type_Id, Vector, Account_Id, Exchanged, Misc, Uri) :-
	doc_new_uri(Uri, st),
	doc_add(Uri, rdf:type, l:s_transaction, transactions),
	doc_add(Uri, s_transactions:day, Day, transactions),
	doc_add(Uri, s_transactions:type_id, Type_Id, transactions),
	doc_add(Uri, s_transactions:vector, Vector, transactions),
	doc_add(Uri, s_transactions:account, Account_Id, transactions),
	doc_add(Uri, s_transactions:exchanged, Exchanged, transactions),
	doc_add(Uri, s_transactions:misc, Misc, transactions).

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

doc_set_s_transaction_vector(T0, X, T1) :-
	doc_set_property(s_transactions, T0, $>s_transaction_fields, vector, X, transactions, T1).

doc_set_s_transaction_type_id(T0, X, T1) :-
	doc_set_property(s_transactions, T0, $>s_transaction_fields, type_id, X, transactions, T1).

/* add a new object with P newly set to V, referencing the rest of Fields */
doc_set_property(Prefix, S1, Fields, P, V, G, S2) :-
	doc_new_uri(S2),
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


pretty_string(T, String) :-
	doc(T, rdf:type, l:s_transaction, transactions),
	s_transaction_day(T, Date),
	s_transaction_type_id(T, uri(Action_Verb)),
	s_transaction_vector(T, Money),
	s_transaction_account(T, Account),
	s_transaction_exchanged(T, Exchanged),
	s_transaction_misc(T, Misc),
	doc(Action_Verb, l:has_id, Action_Verb_Name),
	format(string(String), 's_transaction:~n  date:~q~n  verb:~w~n  vector: ~q~n  account: ~q~n  exchanged: ~q~n  misc: ~q', [Date, Action_Verb_Name, Money, Account, Exchanged, Misc]).


compare_s_transactions(Order, T1, T2) :-
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
	s_transaction_account(T, Account),
	s_transaction_exchanged(T, Exchanged),
	s_transaction_misc(T, Misc),
	(	/* here's an example of the shortcoming of ignoring the rdf prefix issue, fixme */
		doc(Action_Verb, l:has_id, Verb_Label)
	->	true
	;	Verb_Label = Action_Verb),
	D = _{
		date: Day,
		verb: Verb_Label,
		vector: Vector,
		account: Account,
		exchanged: Exchanged,
		misc: Misc}.

prepreprocess(Static_Data, In, Out) :-
	/*
	at this point:
	s_transactions are sorted by date from oldest to newest
	s_transactions have flipped vectors, so they are from our perspective
	*/
	maplist(prepreprocess_s_transaction(Static_Data), In, Out).

prepreprocess_s_transaction(Static_Data, In, Out) :-
	infer_exchanged_units_count(Static_Data, In, Mid),
	!,
	prepreprocess_s_transaction(Static_Data, Mid, Out).

/* add livestock verb uri */
prepreprocess_s_transaction(Static_Data, In, Out) :-
	infer_livestock_action_verb(In, Mid),
	!,
	prepreprocess_s_transaction(Static_Data, Mid, Out).

/* from verb label to verb uri */
prepreprocess_s_transaction(Static_Data, S_Transaction, Out) :-
	s_transaction_action_verb(S_Transaction, Action_Verb),
	!,
	doc_set_s_transaction_type_id(S_Transaction, uri(Action_Verb), NS_Transaction),
	prepreprocess_s_transaction(Static_Data, NS_Transaction, Out).

prepreprocess_s_transaction(_, T, T) :-
	(	s_transaction_type_id(T, uri(_))
	->	true
	;	throw_string(unrecognized_bank_statement_transaction_format)).


% This Prolog rule handles the case when only the exchanged units are known (for example GOOG)  and
% hence it is desired for the program to infer the count.
infer_exchanged_units_count(Static_Data, S_Transaction, NS_Transaction) :-
	dict_vars(Static_Data, [Exchange_Rates]),
	s_transaction_exchanged(S_Transaction, bases(Goods_Bases)),
	s_transaction_day(S_Transaction, Transaction_Date),
	s_transaction_type_id(S_Transaction, Type_Id),
	s_transaction_vector(S_Transaction, Vector),
	s_transaction_account(S_Transaction, Unexchanged_Account_Id),
	s_transaction_misc(S_Transaction, Misc),
	% infer the count by money debit/credit and exchange rate
	vec_change_bases(Exchange_Rates, Transaction_Date, Goods_Bases, Vector, Vector_Exchanged),
	vec_inverse(Vector_Exchanged, Vector_Exchanged_Inverted),
	doc_add_s_transaction(Transaction_Date, Type_Id, Vector, Unexchanged_Account_Id, vector(Vector_Exchanged_Inverted), Misc, NS_Transaction).

/* used on raw s_transaction during prepreprocessing */
s_transaction_action_verb(S_Transaction, Action_Verb) :-
	s_transaction_type_id(S_Transaction, Type_Id),
	Type_Id \= uri(_),
	(	(
			action_verb(Action_Verb),
			doc(Action_Verb, l:has_id, Type_Id)
		)
	->	true
	;	(/*gtrace,*/throw_string(['action verb not found by id:',Type_Id]))).


% yield all transactions from all accounts one by one.
% these are s_transactions, the raw transactions from bank statements. Later each s_transaction will be preprocessed
% into multiple transaction terms.
extract_s_transactions_from_accountDetails_dom(Account, S_Transactions) :-
	catch(
		fields(Account, [
			accountName, Account_Name,
			currency, Account_Currency
			]),
			E,
			(
				pretty_term_string(E, E_Str),
				throw(http_reply(bad_request(string(E_Str)))))
			)
	,extract_s_transactions_from_accountDetails_dom2(Account_Currency, Account_Name, Account, S_Transactions).

extract_s_transactions_from_accountDetails_dom2(Account_Currency, Account_Name, Account, S_Transactions) :-
	findall(Tx_Dom, xpath(Account, transactions/transaction, Tx_Dom), Tx_Doms),
	maplist(extract_s_transaction(Account_Currency, Account_Name), Tx_Doms, S_Transactions).

extract_s_transaction(Account_Currency, Account_Name, Tx_Dom, S_Transaction) :-
	catch(
		extract_s_transaction2(Tx_Dom, Account_Currency, Account_Name, S_Transaction),
		Error,
		(
			term_string(Error, Str1),
			term_string(Tx_Dom, Str2),
			atomic_list_concat([Str1, Str2], Message),
			throw(Message)
		)),
	true.

extract_s_transaction2(Tx_Dom, Account_Currency, Account, ST) :-
	numeric_fields(Tx_Dom, [
		debit, (Bank_Debit, 0),
		credit, (Bank_Credit, 0)]),
	fields(Tx_Dom, [
		transdesc, (Desc1, ''),
		transdesc2, (Desc2, '')
	]),
	xpath(Tx_Dom, transdate, element(_,_,[Date_Atom])),
	parse_date(Date_Atom, Date),
	Dr is rationalize(Bank_Debit - Bank_Credit),
	Coord = coord(Account_Currency, Dr),
	extract_exchanged_value(Tx_Dom, Account_Currency, Dr, Exchanged),
	doc_add_s_transaction(Date, Desc1, [Coord], Account, Exchanged, misc{desc2:Desc2}, ST),
	doc_add(ST, l:source, l:bank_statement_xml).

extract_exchanged_value(Tx_Dom, _Account_Currency, Bank_Dr, Exchanged) :-
   % if unit type and count is specified, unifies Exchanged with a one-item vector with a coord with those values
   % otherwise unifies Exchanged with bases(..) to trigger unit conversion later
   (
	  field_nothrow(Tx_Dom, [unitType, Unit_Type]),
	  (
		 (
			field_nothrow(Tx_Dom, [unit, Unit_Count_Atom]),
			atom_number(Unit_Count_Atom, Unit_Count),
			Count_Absolute is rationalize(abs(Unit_Count)),
			(
				Bank_Dr >= 0
			->
					Exchanged = vector([coord(Unit_Type, Count_Absolute)])
			;
				(
					Count_Credit is -Count_Absolute,
					Exchanged = vector([coord(Unit_Type, Count_Credit)])
				)
			),
			!
		 )
		 ;
		 (
			% If the user has specified only a unit type, then infer count by exchange rate
			Exchanged = bases([Unit_Type])
		 )
	  ),!
   )
   ;
   (
	  Exchanged = vector([])
   ).

extract_s_transactions(Dom, S_Transactions) :-
	findall(A, xpath(Dom, //reports/balanceSheetRequest/bankStatement/accountDetails, A), As),
	maplist(extract_s_transactions_from_accountDetails_dom, As, S_Transactions0),
	flatten(S_Transactions0, S_Transactions1),
	maplist(invert_s_transaction_vector, S_Transactions1, S_Transactions).


invert_s_transaction_vector(T0, T1) :-
	s_transaction_vector(T0, Vector),
	vec_inverse(Vector, Vector_Inverted),
	doc_set_s_transaction_vector(T0, Vector_Inverted, T1).



handle_additional_files(S_Transactions) :-
	request_data(Request_Data),
	(	doc_value(Request_Data, ic_ui:additional_files, Files)
	->	(
			maplist(handle_additional_file, $> doc_list_items(Files), S_Transactions0),
			flatten(S_Transactions0, S_Transactions)
		)
	;	S_Transactions = []).

handle_additional_file(Bn, S_Transactions) :-
	(	extract_german_bank_csv0(Bn, S_Transactions)
	->	true
	;	throw_string(['unrecognized file format (', Bn, ')'])).

