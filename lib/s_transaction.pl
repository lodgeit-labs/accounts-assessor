:- use_module(library(dcg/basics)).

%:- record s_transaction(day, type_id, vector, account_id, exchanged, misc).
% bank statement transaction record, these are in the input xml
% - The absolute day that the transaction happenned
% - The type identifier/action tag of the transaction
% - The amounts that are being moved in this transaction
% - The account that the transaction modifies without using exchange rate conversions
% - Either the units or the amount to which the transaction amount will be converted to, depending on whether the term is of the form bases(...) or vector(...).

make_s_transaction(Uri) :-
	doc_new_uri(Uri),
	doc_add(Uri, rdf:type, l:s_transaction),
	doc_add(Uri, s_transactions:type_id, Type_Id),
	doc_add(Uri, s_transactions:vector, Vector),
	doc_add(Uri, s_transactions:account_id, Account_Id),
	doc_add(Uri, s_transactions:exchanged, Exchanged),
	doc_add(Uri, s_transactions:misc, Misc).

s_transaction_day(T, D) :-
	doc(T, s_transactions:day, D, transactions).
s_transaction_type_id(T, X) :-
	doc(T, s_transactions:type_id, X, transactions).
s_transaction_vector(T, X) :-
	doc(T, s_transactions:vector, X, transactions).
s_transaction_account_id(T, X) :-
	doc(T, s_transactions:account_id, X, transactions).
s_transaction_exchanged(T, X) :-
	doc(T, s_transactions:exchanged, X, transactions).
s_transaction_misc(T, X) :-
	doc(T, s_transactions:misc, X, transactions).



pretty_string(T, String) :-
	doc(S_Transaction, rdf:type l:s_transaction),
	s_transaction_day(T, Date),
	s_transaction_type_id(T, uri(Action_Verb)),
	s_transaction_vector(T, Money),
	s_transaction_account(T, Account)
	s_transaction_exchanged(T, Exchanged),
	s_transaction_misc(T, Misc),
	doc(Action_Verb, l:has_id, Action_Verb_Name),
	format(string(String), 's_transaction:~n  date:~q~n  verb:~w~n  vector: ~q~n  account: ~q~n  exchanged: ~q~n  misc: ~q', [Date, Action_Verb_Name, Money, Account, Exchanged, Misc]).


compare_s_transaction_vector_debit(Order, T1, T2) :-
	doc(T1, s_transactions:vector, [coord(_, Debit1)]),
	doc(T2, s_transactions:vector, [coord(_, Debit2)]),
	compare(Order, Debit1, Debit2).

compare_s_transaction_day(Order, T1, T2) :-
	s_transaction_day(T1, Day1),
	s_transaction_day(T2, Day2),
	compare(Order, Day1, Day2).


sort_s_transactions(In, Out) :-
	/*maybe todo:
	even smarter sorting.
	First, all revenue, that is, no exchanged, debit vector
	next, exchanged debit
	then the rest?
	*/
	/* If a buy and a sale of same thing happens on the same day, we want to process the buy first.
	We first sort by our debit on the bank account. Transactions with zero of our debit are not sales. */
	predsort(compare_s_transaction_vector_debit, In, Mid),
	/*	now we can sort by date ascending, and the ordering of transactions with same date, as sorted above, will be preserved	*/
	predsort(compare_s_transaction_day, Mid, Out).

s_transactions_up_to(End_Date, S_Transactions_In, S_Transactions_Out) :-
	findall(
		T,
		(
			member(T, S_Transactions_In),
			s_transaction_day(T, D),
			D @=< End_Date
		),
		S_Transactions_Out
	).

s_transaction_to_dict(T, D) :-
	doc(S_Transaction, rdf:type l:s_transaction),
	s_transaction_day(T, Date),
	s_transaction_type_id(T, uri(Action_Verb)),
	s_transaction_vector(T, Money),
	s_transaction_account(T, Account)
	s_transaction_exchanged(T, Exchanged),
	s_transaction_misc(T, Misc),
	(	/* here's an example of the shortcoming of ignoring the rdf prefix issue, fixme */
		doc(Verb, l:has_id, Verb_Label)
	->	true
	;	Verb_Label = Verb),
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
	s_transactions have to be sorted by date from oldest to newest
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
	set_s_transaction_type_id(S_Transaction, uri(Action_Verb), NS_Transaction),
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
	s_transaction_account_id(S_Transaction, Unexchanged_Account_Id),
	% infer the count by money debit/credit and exchange rate
	vec_change_bases(Exchange_Rates, Transaction_Date, Goods_Bases, Vector, Vector_Exchanged),
	vec_inverse(Vector_Exchanged, Vector_Exchanged_Inverted),
	doc_add_s_transaction(Transaction_Date, Type_Id, Vector, Unexchanged_Account_Id, vector(Vector_Exchanged_Inverted), transactions, NS_Transaction).

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
% fixme dont fail silently
extract_s_transaction(Dom, Start_Date, Transaction) :-
	xpath(Dom, //reports/balanceSheetRequest/bankStatement/accountDetails, Account),
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
	,
	xpath(Account, transactions/transaction, Tx_Dom),
	catch(
		extract_s_transaction2(Tx_Dom, Account_Currency, Account_Name, Start_Date, Transaction),
		Error,
		(
			term_string(Error, Str1),
			term_string(Tx_Dom, Str2),
			atomic_list_concat([Str1, Str2], Message),
			throw(Message)
		)),
	true.

extract_s_transaction2(Tx_Dom, Account_Currency, Account, Start_Date, ST) :-
	numeric_fields(Tx_Dom, [
		debit, (Bank_Debit, 0),
		credit, (Bank_Credit, 0)]),
	fields(Tx_Dom, [
		transdesc, (Desc1, ''),
		transdesc2, (Desc2, '')
	]),
	(
		(
			xpath(Tx_Dom, transdate, element(_,_,[Date_Atom]))
			,
			!
		)
		;
		(
			Date_Atom=Start_Date,
			writeln("date missing, assuming beginning of request period") % todo dunno if this is needed
		)
	),
	parse_date(Date_Atom, Date),
	Dr is rationalize(Bank_Debit - Bank_Credit),
	Coord = coord(Account_Currency, Dr),
	doc_add_s_transaction(Date, Desc1, [Coord], Account, Exchanged, misc{desc2:Desc2}, transactions, ST),
	doc_add(ST, l:source, l:bank_statement_xml),
	extract_exchanged_value(Tx_Dom, Account_Currency, Dr, Exchanged).

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

extract_s_transactions(Dom, Start_Date_Atom, S_Transactions) :-
	findall(S_Transaction, extract_s_transaction(Dom, Start_Date_Atom, S_Transaction), S_Transactions0),
	maplist(invert_s_transaction_vector, S_Transactions0, S_Transactions).


invert_s_transaction_vector(T0, T1) :-
	doc(T0, s_transactions:vector, Vector),
	vec_inverse(Vector, Vector_Inverted),
	doc_set_s_transaction_field(T0, (s_transactions:vector)(Vector_Inverted), transactions, T1).



handle_additional_files(S_Transactions) :-
	(	doc_value(l:request, ic_ui:additional_files, Files)
	->	(
			maplist(handle_additional_file, $> doc_list_items(Files), S_Transactions0),
			flatten(S_Transactions0, S_Transactions)
		)
	;	S_Transactions = []).

handle_additional_file(Bn, S_Transactions) :-
	(	extract_german_bank_csv0(Bn, S_Transactions)
	->	true
	;	throw_string(['unrecognized file format (', Bn, ')'])).

:- use_module(library(uri)).

extract_german_bank_csv0(Bn, S_Transactions) :-
	doc_value(Bn, ic:url, Url0),
	trim_string(Url0, Url),
	exclude_file_location_from_filename(loc(_,Url), Fn),
	absolute_tmp_path(Fn, Tmp_File_Path),
	fetch_file_from_url(loc(absolute_url, Url), Tmp_File_Path),
	extract_german_bank_csv1(Tmp_File_Path, S_Transactions).

extract_german_bank_csv1(File_Path, S_Transactions) :-
	loc(absolute_path, File_Path_Value) = File_Path,
	exclude_file_location_from_filename(File_Path, Fn),
	Fn = loc(file_name, Fn_Value0),
	uri_encoded(path, Fn_Value1, Fn_Value0),
	open(File_Path_Value, read, Stream),
	/*skip the header*/
	Header = `Buchung;Valuta;Text;Betrag;;Ursprung`,
	read_line_to_codes(Stream, Header_In),
	(	Header_In = Header
	->	true
	;	throw_string([Fn_Value1, ': expected header not found: ', Header])),
	csv_read_stream(Stream, Rows, [separator(0';)]),
	Account = Fn_Value1,
	string_codes(Fn_Value1, Fn_Value2),
	phrase(gb_currency_from_fn(Currency0), Fn_Value2),
	atom_codes(Currency, Currency0),
	maplist(german_bank_csv_row(Account, Currency), Rows, S_Transactions).

german_bank_csv_row(Account, Currency, Row, S_Transaction) :-
	Row = row(Date0, _, Description, Money_Atom, Side, Description_Column2),
	%gtrace,
	string_codes(Date0, Date1),
	phrase(gb_date(Date), Date1),
	german_bank_money(Money_Atom, Money_Number),
	(	Side == 'H'
	->	Money_Amount is Money_Number
	;	Money_Amount is -Money_Number),
	Vector = [coord(Currency, Money_Amount)],
	string_codes(Description, Description2),
	(	phrase(gbtd2(desc(Verb,Exchanged)), Description2)
	->	true
	;	(
			add_alert('error', ['failed to parse description: ', Description]),
			%gtrace,
			Exchanged = vector([]),
			Verb = '?'
		)
	),
	(	Side == 'S'
	->	Exchanged2 = Exchanged
	;	(
			vector(E) = Exchanged,
			vec_inverse(E, E2),
			Exchanged2 = vector(E2)
		)
	),
	doc_add_s_transaction(Date, Verb, Vector, Account, Exchanged2, misc{desc2:Description,desc3:Description_Column2}, transactions, S_Transaction).

german_bank_money(Money_Atom0, Money_Number) :-
	filter_out_chars_from_atom(([X]>>(X == '\'')), Money_Atom0, Money_Atom1),
	atom_codes(Money_Atom1, Money_Atom2),
	phrase(number(Money_Number0), Money_Atom2),
	Money_Number is rational(Money_Number0).

/* german bank transaction description */
gbtd('Zinsen') -->                 "Zinsen ", remainder(_).
gbtd('Verfall_Terming') -->        "Verfall Terming. ", remainder(_). % futures?
gbtd('Inkasso') -->                "Inkasso ", remainder(_).
gbtd('Belastung') -->              "Belastung ", remainder(_).
gbtd('Barauszahlung') -->          "Barauszahlung".
gbtd('Devisen_Spot') -->           "Devisen Spot", remainder(_).
gbtd('Vergutung_Cornercard') -->   "Vergütung Cornercard".
gbtd('Ruckzahlung') -->            "Rückzahlung", remainder(_).
gbtd('All-in-Fee') -->             "All-in-Fee".

gbtd2(desc('Zeichnung',vector([coord(Unit, Count)]))) --> "Zeichnung ", gb_number(Count), " ", remainder(Codes), {atom_codes(Unit, Codes)}.
gbtd2(desc('Kauf',     vector([coord(Unit, Count)]))) --> "Kauf ",      gb_number(Count), " ", remainder(Codes), {atom_codes(Unit, Codes)}.
gbtd2(desc('Verkauf',  vector([coord(Unit, Count)]))) --> "Verkauf ",   gb_number(Count), " ", remainder(Codes), {atom_codes(Unit, Codes)}.

gbtd2(desc(Verb,vector([]))) --> gbtd(Verb).





gb_number(X) --> gb_number_chars(Y), {phrase(number(X), Y)}.
gb_number_chars([H|T]) --> digit(H), gb_number_chars(T).
gb_number_chars([0'.|T]) --> ".", gb_number_chars(T).
gb_number_chars(T) --> "'", gb_number_chars(T).
gb_number_chars([]) --> [].

gb_currency_from_fn(Currency) --> integer(_), white, string_without(" ", Currency), remainder(_).

gb_date(date(Y, M, D)) --> integer(D), ".", integer(M), ".", integer(Y).

