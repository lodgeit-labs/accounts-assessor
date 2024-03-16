
/* stringify table cells. Currently also produces bits of html. This will have to be abstracted. */


 stringify_table_cells(Target, T1,T2) :-
	table{columns:Columns, rows:Rows} :< T1,
	maplist(format_row(Target, Columns),Rows,Formatted_Rows),
	T2 = T1.put(rows, Formatted_Rows).

 format_row(Target, Columns, Row, Formatted_Row) :-
	findall(KV, formatted_row_kvs(Target, Columns, Row, KV), Formatted_Row_KVs),
	!dict_create(Formatted_Row,row,Formatted_Row_KVs).

 formatted_row_kvs(Target, Columns, Row, KV) :-
	member(Column, Columns),
	get_dict(id, Column, Column_id),
	(	get_dict(Column_id, Row, _)
	->	format_column(Target, Column, Row, KV)
	;	KV = (Column_id:'')).

 format_column(Target, Dict, Row, Column_ID:Formatted_Group) :-
	group{id:Column_ID, members:Group_Members} :< Dict,
	format_row(Target, Group_Members, Row.Column_ID, Formatted_Group).

 format_column(Target, Dict, Row, Column_ID:Formatted_Cell) :-
	column{id:Column_ID, options:Column_Options} :< Dict,
	format_cell(Target, Row.Column_ID, Column_Options, Formatted_Cell).






/*dates*/

format_cell(html, Date, _, Output) :-
	Date = date(_,_,_),
	format_date(Date, Output),
	!.

format_cell(excel, Date, _, Date) :-
	Date = date(_,_,_),
	!.

%format_cell(excel, Date, _, excel_date(Output)) :-
%	/*Excel stores dates as sequential serial numbers so that they can be used in calculations. By default, January 1, 1900 is serial number 1, and January 1, 2008 is serial number 39448 because it is 39,447 days after January 1, 1900.*/
%	Date = date(_,_,_),
%	absolute_day(Date, Since_year_0),
%	absolute_day(date(1,1,1900), Since_year_1900),
%	Output is Since_year_0 - Since_year_1900,
%	!.
%




/*lists*/

format_cell(_Target, [], _Options, []) :- !.

format_cell(Target, [X|Xs], Options, [Output1, Output2]) :-
	format_cell(Target, X, Options, Output1),
	format_cell(Target, Xs, Options, Output2),
	!.





/*?*/
format_cell(Target, with_metadata(Value, _), Options, Output) :-
	format_cell(Target, Value, Options, Output),
	!.





/*
augment the result with a rdf link.
*/
format_cell(html, with_metadata(Value, _, Uri), Options, [Output, A]) :-
	format_cell(html, Value, Options, Output),
	!,
	link(Uri, A).

format_cell(excel, with_metadata(Value, _, Uri), Options, [Output, '->', Uri]) :-
	format_cell(excel, Value, Options, Output),
	!.






format_cell(html, value(Unit, Value), Options, div([class=money_amount], [Output])) :-
	(	Precision = Options.get(precision)
	->	true
	;	Precision = 2),

	(	true = Options.get(implicit_report_currency)
	->	!result_property(l:report_currency, Optional_Implicit_Unit)
	;	Optional_Implicit_Unit = []),
	format_money2(Optional_Implicit_Unit, Precision, value(Unit, Value), Output),
	!.

format_cell(excel, value(Unit, Value), Options, Output) :-
	(	Precision = Options.get(precision)
	->	true
	;	Precision = 2),

	(	(
			true = Options.get(implicit_report_currency)
			;
			true = Options.get(implicit_report_currency_only_for_excel)
		)
	->	!result_property(l:report_currency, Optional_Implicit_Unit)
	;	Optional_Implicit_Unit = []),

	(	[Unit] = Optional_Implicit_Unit
	->	Output = money(Value)
	;	format_money2([], Precision, value(Unit, Value), Output)
	),
	!.






format_cell(_, exchange_rate(Date, Src, Dst, Rate), _, Output) :-
	format_conversion(_, exchange_rate(Date, Src, Dst, Rate), Output),
	!.






format_cell(_, Other, _, Other) :-
	atom(Other),!.

format_cell(html, Other, _, Other) :-
	Other = hr([]),!.

format_cell(excel, Other, _, '———') :-
	Other = hr([]),
	!.

format_cell(_, text(X), _, X) :-
	!.

format_cell(_, Other, _, Str) :-
	round_term(Other, Other2),
	term_string(Other2, Str).





format_money2(Optional_Implicit_Unit, Precision, In, Out_Str) :-
	(	In = ''
	->	Out_Str = ''
	;	(	In = value(Unit1,X)
		->	true
		;	(
				X = In,
				Unit1 = '???'
			)
		),
		(
			member(Unit1, Optional_Implicit_Unit)
		->	Unit2 = ''
		;	Unit2 = Unit1
		),
		atomic_list_concat(['~',Precision,':f~w'], Format_String),
		format(string(Out_Str), Format_String, [X, Unit2])
	).


format_conversion(_Report_Currency, '', '').

format_conversion(_Report_Currency, Conversion, String) :-
	Conversion = exchange_rate(_, Src, Dst, Rate),
	Inverse is 1 / Rate,
	format(string(String), '1~w=~6:f~w', [Dst, Inverse, Src]).
	%pretty_term_string(Conversion, String).


