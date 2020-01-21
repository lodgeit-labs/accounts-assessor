
%:- rdet(s_transaction_to_dict/2).

:- record s_transaction(day, type_id, vector, account_id, exchanged).
% bank statement transaction record, these are in the input xml
% - The absolute day that the transaction happenned
% - The type identifier/action tag of the transaction
% - The amounts that are being moved in this transaction
% - The account that the transaction modifies without using exchange rate conversions
% - Either the units or the amount to which the transaction amount will be converted to
% depending on whether the term is of the form bases(...) or vector(...).

sort_s_transactions(In, Out) :-
	/*maybe todo:
	even smarter sorting.
	First, all revenue, that is, no exchanged, debit vector
	next, exchanged debit
	then the rest?
	*/
	/*
	If a buy and a sale of same thing happens on the same day, we want to process the buy first.
	We first sort by our debit on the bank account. Transactions with zero of our debit are not sales.
	*/
	sort(
	/*
	this is a path inside the structure of the elements of the sorted array (inside the s_transactions):
	3th sub-term is the transaction vector from our perspective
	1st (and hopefully only) item of the vector is a coord,
	2rd item of the coord is our bank account debit.
	*/
	[3,1,2], @=<,  In, Mid),
	/*
	now we can sort by date ascending, and the order of transactions with same date, as sorted above, will be preserved
	*/
	sort(1, @=<,  Mid, Out).

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

s_transaction_to_dict(St, D) :-
	St = s_transaction(Day, uri(Verb), Vector, Account, Exchanged),
	(	/* here's an example of the shortcoming of ignoring the rdf prefix issue, fixme */
		doc(Verb, l:has_id, Verb_Label)
	->	true
	;	Verb_Label = Verb),
	D = _{
		date: Day,
		verb: Verb_Label,
		vector: Vector,
		account: Account,
		exchanged: Exchanged}.

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
	s_transaction_type_id(NS_Transaction, uri(Action_Verb)),
	/* just copy these over */
	s_transaction_exchanged(S_Transaction, Exchanged),
	s_transaction_exchanged(NS_Transaction, Exchanged),
	s_transaction_day(S_Transaction, Transaction_Date),
	s_transaction_day(NS_Transaction, Transaction_Date),
	s_transaction_vector(S_Transaction, Vector),
	s_transaction_vector(NS_Transaction, Vector),
	s_transaction_account_id(S_Transaction, Unexchanged_Account_Id),
	s_transaction_account_id(NS_Transaction, Unexchanged_Account_Id),
	prepreprocess_s_transaction(Static_Data, NS_Transaction, Out).

prepreprocess_s_transaction(_, T, T) :-
	(	s_transaction_type_id(T, uri(_))
	->	true
	;	throw_string(unrecognized_bank_statement_transaction)).


% This Prolog rule handles the case when only the exchanged units are known (for example GOOG)  and
% hence it is desired for the program to infer the count.
infer_exchanged_units_count(Static_Data, S_Transaction, NS_Transaction) :-
	dict_vars(Static_Data, [Exchange_Rates]),
	s_transaction_exchanged(S_Transaction, bases(Goods_Bases)),
	s_transaction_day(S_Transaction, Transaction_Date),
	s_transaction_day(NS_Transaction, Transaction_Date),
	s_transaction_type_id(S_Transaction, Type_Id),
	s_transaction_type_id(NS_Transaction, Type_Id),
	s_transaction_vector(S_Transaction, Vector_Bank),
	s_transaction_vector(NS_Transaction, Vector_Bank),
	s_transaction_account_id(S_Transaction, Unexchanged_Account_Id),
	s_transaction_account_id(NS_Transaction, Unexchanged_Account_Id),
	% infer the count by money debit/credit and exchange rate
	vec_change_bases(Exchange_Rates, Transaction_Date, Goods_Bases, Vector_Bank, Vector_Exchanged),
	vec_inverse(Vector_Exchanged, Vector_Exchanged_Inverted),
	s_transaction_exchanged(NS_Transaction, vector(Vector_Exchanged_Inverted)).

/* used on raw s_transaction during prepreprocessing */
s_transaction_action_verb(S_Transaction, Action_Verb) :-
	s_transaction_type_id(S_Transaction, Type_Id),
	Type_Id \= uri(_),
	(	(
			action_verb(Action_Verb),
			doc(Action_Verb, l:has_id, Type_Id)
		)
	->	true
	;	(/*gtrace,*/throw_string(['unknown action verb:',Type_Id]))).


% yield all transactions from all accounts one by one.
% these are s_transactions, the raw transactions from bank statements. Later each s_transaction will be preprocessed
% into multiple transaction(..) terms.
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
		transdesc, (Desc, '')
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
	ST = s_transaction(Date, Desc, [Coord], Account, Exchanged),
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
				Bank_Dr > 0
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
	maplist(invert_s_transaction_vector, S_Transactions0, S_Transactions0b),
	sort_s_transactions(S_Transactions0b, S_Transactions).


invert_s_transaction_vector(T0, T1) :-
	T0 = s_transaction(Date, Type_id, Vector, Account_id, Exchanged),
	T1 = s_transaction(Date, Type_id, Vector_Inverted, Account_id, Exchanged),
	vec_inverse(Vector, Vector_Inverted).



handle_additional_files(S_Transactions) :-
	maplist(handle_additional_file, $> doc_list_items($> doc_value(l:request, ic_ui:additional_files)), S_Transactions0),
	flatten(S_Transactions0, S_Transactions).

handle_additional_file(Bn, S_Transactions) :-
	(	extract_german_bank_csv0(Bn, S_Transactions)
	->	true
	;	throw_string(['unrecognized file (', Bn, ')'])).

:- use_module(library(uri)).

extract_german_bank_csv0(Bn, S_Transactions) :-
	doc_value(Bn, ic:url, Url),
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
	Row = row(Date, _, Desc, Money_Atom, Side, _),
	writeq((german_bank_csv_row(Account, Currency, Row, S_Transaction),
	 row(Date, _, Desc, Money_Atom, Side, _))),	gtrace,
	/*,
	Date,
	Side,
	phrase(german_bank_money, Money_Atom, Money_Number),
	(	Side == 'H'
	->	Money_Amount is Money_Number
	;	Money_Amount is -Money_Number),
	Vector = [coord(Currency, Money_Amount)],
	(	phrase(gbtd(Verb), Description)
	->	true
	;	add_alert(['failed to parse description: ', Description])),
	S_Transaction = s_transaction(Date, Verb, Vector, Account, Exchanged).
	*/
	true.

/* german bank transaction description */
:- use_module(library(dcg/basics)).

gbtd('Expenses') --> [`Verfall Terming. `].

gb_currency_from_fn(Currency) --> integer(_), white, string_without(" ", Currency), remainder(_).


/* todo alerts html */
