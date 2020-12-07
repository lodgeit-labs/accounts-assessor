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
	doc_add_s_transaction(Date, Verb, Vector, bank_account_name(Account), Exchanged2, misc{desc2:Description,desc3:Description_Column2}, S_Transaction).

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

