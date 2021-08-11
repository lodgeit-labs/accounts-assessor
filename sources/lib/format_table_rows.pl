
format_table_rows(
	table{title:Title, columns:Columns, rows:Rows},
	table{title:Title, columns:Columns, rows:Formatted_Rows}
) :-
	maplist(format_row(Columns),Rows,Formatted_Rows).

 format_row(Columns, Row, Formatted_Row) :-
	findall(KV, formatted_row_kvs(Columns, Row, KV), Formatted_Row_KVs),
	!dict_create(Formatted_Row,row,Formatted_Row_KVs).

 formatted_row_kvs(Columns, Row, KV) :-
	member(Column, Columns),
	get_dict(id, Column, Column_id),
	(	get_dict(Column_id, Row, _)
	->	format_column(Column, Row, KV)
	;	KV = (Column_id:'')).

 format_column(Dict, Row, Column_ID:Formatted_Group) :-
	group{id:Column_ID, title:_, members:Group_Members} :< Dict,
	format_row(Group_Members, Row.Column_ID, Formatted_Group).

 format_column(Dict, Row, Column_ID:Formatted_Cell) :-
	column{id:Column_ID, options:Column_Options} :< Dict,
	format_cell(Row.Column_ID, Column_Options, Formatted_Cell).


format_cell(Date, _, Output) :-
	Date = date(_,_,_),
	format_date(Date, Output),
	!.

format_cell([], _Options, []) :- !.

format_cell([X|Xs], Options, [Output1, Output2]) :-
	format_cell(X, Options, Output1),
	format_cell(Xs, Options, Output2),
	%atomic_list_concat([Output1, ', ', Output2], Output),
	!.

format_cell(with_metadata(Value, _), Options, Output) :-
	format_cell(Value, Options, Output),
	!.
/*
format_cell(with_metadata(Value, _, _Uri), Options, Output) :-
	format_cell(Value, Options, Output),
	!.
*/
format_cell(with_metadata(Value, _, Uri), Options, [Output, A]) :-
	format_cell(Value, Options, Output),
	!,

/*html*/
	link(Uri, A).



format_cell(value(Unit, Value), Options, Output) :-
	(	Precision = Options.get(precision)
	->	true
	;	Precision = 2),
	(	true = Options.get(implicit_report_currency)
	->	!result_property(l:report_currency, Optional_Implicit_Unit)
	;	Optional_Implicit_Unit = []),
	format_money2(Optional_Implicit_Unit, Precision, value(Unit, Value), Output),
	!.

format_cell(exchange_rate(Date, Src, Dst, Rate), _, Output) :-
	format_conversion(_, exchange_rate(Date, Src, Dst, Rate), Output),
	!.

format_cell(Other, _, Other) :-
	atom(Other),!.

format_cell(Other, _, Other) :-



/*html*/
	Other = hr([]),!.




format_cell(text(X), _, X) :-
	!.

format_cell(Other, _, Str) :-
	term_string(Other, Str).

format_money2(Optional_Implicit_Unit, Precision, In, Out) :-
	(
		In = ''
	->
		Out = ''
	;
		(
			In = value(Unit1,X)
		->
			true
		;
			(
				X = In,
				Unit1 = '?'
			)
		),
		(
			member(Unit1, Optional_Implicit_Unit)
		->
			Unit2 = ''
		;
			Unit2 = Unit1
		),
		atomic_list_concat(['~',Precision,':f~w'], Format_String),
		format(string(Out_Str), Format_String, [X, Unit2]),



/*html*/
		Out = div([class=money_amount], [Out_Str])



	).


format_conversion(_Report_Currency, '', '').

format_conversion(_Report_Currency, Conversion, String) :-
	Conversion = exchange_rate(_, Src, Dst, Rate),
	Inverse is 1 / Rate,
	format(string(String), '1~w=~6:f~w', [Dst, Inverse, Src]).
	%pretty_term_string(Conversion, String).


