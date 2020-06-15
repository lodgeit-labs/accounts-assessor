/*
  <abstract representation of a table> to <html something>
*/
 table_html(
	Options,
	Table, 
	/*[div([span([Table.title, ':']), HTML_Table])]*/
	HTML_Table
) :-
	format_table(Table, Formatted_Table),
	table_contents_to_html(Options, Formatted_Table, HTML_Table).

/*
  this one converts the actual tabular data in the report to an
  actual html table
  first argument - internal representation of tabular data, formatted into strings, flat?
  second argument - html_write table term/input
  
*/
table_contents_to_html(
	Options,
	table{title:_, columns: Columns, rows: Rows},
	[HTML_Header | HTML_Rows]
) :-
	header_html(Columns, HTML_Header),
	rows_to_html(Columns, Rows, HTML_Rows0),
	(	member(highlight_totals - true, Options)
	->	highlight_totals(HTML_Rows0,HTML_Rows)
	;	HTML_Rows0 = HTML_Rows).

rows_to_html(Columns, Rows, Html3) :-
	maplist(row_to_html(Columns), Rows, Html1),
	findall(tr(Row_Flat), (member(Row, Html1), flatten(Row, Row_Flat)), Html3).


highlight_totals([Row1, Row2 | Rows], [Row1 | Highlighted]) :-
	highlight_totals([Row2 | Rows], Highlighted).

highlight_totals([tr(Row)], [tr([style="background-color:#DDDDEE; font-weight:bold"],Row)]).


header_html(Columns, tr(Header_Row)) :-
	findall(
		Cells,
		(
			member(Column, Columns),
			column_header_html(Column, "", Cells)
		),
		HTML_Header_Nested
	),
	flatten(HTML_Header_Nested, Header_Row).

column_header_html(group{id:_, title:Group_Title, members:Group_Members}, Prefix, Cells) :-
	(
		Prefix = ""
	->
		Group_Prefix = Group_Title
	;
		atomics_to_string([Prefix, Group_Title], " ", Group_Prefix)
	),
	findall(
		Child_Cells,
		(
			member(Column, Group_Members),
			column_header_html(Column, Group_Prefix, Child_Cells)
		),
		Cells
	).

column_header_html(Dict, Prefix, th(Header_Value)) :-
	column{title: Column_Title, options: Options} :< Dict,
	(
		(Prefix = "" ; get_dict(hide_group_prefix, Options, true))
	->
		Header_Value = Column_Title
	;
		atomics_to_string([Prefix, Column_Title], " ", Header_Value)
	).

row_to_html(Columns, Row, HTML_Row) :-
	findall(
		Cell,
		(
			member(Column, Columns),
			(	get_dict(id, Column, Column_id)
			->	!column_to_html(Column, Row.Column_id, Cell)
			;	Cell = [td([""])])
		),
		HTML_Row
	).

column_to_html(group{id:Group_ID, title:Group_Title, members:Group_Members}, Row, Cells) :-
	(
		Row = ''
	->
		blank_row(group{id:Group_ID, title:Group_Title, members:Group_Members}, Cells)
	;
		row_to_html(Group_Members, Row, Cells)
	).

column_to_html(Dict, Cell, [td(Cell_Flat)]) :-
	is_dict(Dict, column),
	flatten(Cell, Cell_Flat).
/*	(
		Cell = []
	->
		atomics_to_string([Column_Title, "[]"], ": ", Cell_Value)
	;
		atomics_to_string([Column_Title, Cell], ": ", Cell_Value)
	).
*/
blank_row(group{id:_, title:_, members:Group_Members}, Cells) :-
	findall(
		Child_Cells,
		(
			member(Column, Group_Members),
			blank_row(Column, Child_Cells)
		),
		Cells
	).

blank_row(Dict, [td("")]) :-
	is_dict(Dict, column).
	/*atomics_to_string([Column_ID, "Blank"], ": ", Cell_Value).*/


format_table(
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

format_column(group{id:Column_ID, title:_, members:Group_Members}, Row, Column_ID:Formatted_Group) :-
	format_row(Group_Members, Row.Column_ID, Formatted_Group).

format_column(Dict, Row, Column_ID:Formatted_Cell) :-
	column{id:Column_ID, options:Column_Options} :< Dict,
	format_cell(Row.Column_ID, Column_Options, Formatted_Cell).

flatten_groups(Groups, Columns) :-
	findall(
		Group_Columns,
		(
			member(Group, Groups),
			group_columns(Group, Group_Columns)
		),
		Columns_Nested
	),
	flatten(Columns_Nested, Columns).

group_columns(
	group{id:Group_ID, title:Group_Title, members:Group_Members},
	Group_Columns
) :-
	findall(
		Result1,
		(
			member(Column, Group_Members),
			is_dict(Column, column),
			(get_dict(id, Column, Member_ID) -> true ; true),
			get_dict(title, Column, Member_Title),
			get_dict(options, Column, Options),
			atomics_to_string([Group_Title, Member_Title], " ", Column_Title),
			Result0 = column{
				title:Column_Title,
				options:Options
			},
 			(	var(Member_ID)
 			->	Result1 = Result0
 			;	Result1 = Result0.put(id, Group_ID/Member_ID))
		),
		Group_Columns
	).

format_cell(Date, _, Output) :-
	Date = date(_,_,_),
	format_date(Date, Output),
	!.

format_cell([], _Options, []) :- !.

%format_cell([X], Options, Output) :- 
%	format_cell(X, Options, Output),
%	!.

format_cell([X|Xs], Options, [Output1, Output2]) :- 
	format_cell(X, Options, Output1),
	format_cell(Xs, Options, Output2),
	%atomic_list_concat([Output1, ', ', Output2], Output),
	!.

format_cell(with_metadata(Value, _), Options, Output) :-
	format_cell(Value, Options, Output),
	!.

format_cell(value(Unit, Value), Options, Output) :-
	(	Precision = Options.get(precision)
	->	true
	;	Precision = 2),
	(	true = Options.get(implicit_report_currency)
	->	!request_has_property(l:report_currency, Optional_Implicit_Unit)
	;	Optional_Implicit_Unit = []),
	format_money2(Optional_Implicit_Unit, Precision, value(Unit, Value), Output),
	!.

format_cell(exchange_rate(Date, Src, Dst, Rate), _, Output) :-
	format_conversion(_, exchange_rate(Date, Src, Dst, Rate), Output),
	!.

format_cell(Other, _, Other) :-
	atom(Other),!.

format_cell(Other, _, Other) :-
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
		Out = div([class=money_amount], [Out_Str])
	).


format_conversion(_Report_Currency, '', '').
	
format_conversion(_Report_Currency, Conversion, String) :-
	Conversion = exchange_rate(_, Src, Dst, Rate),
	Inverse is 1 / Rate,
	format(string(String), '1~w=~6:f~w', [Dst, Inverse, Src]). 
	%pretty_term_string(Conversion, String).


/* Rows - dict, possibly with subdicts */
/* Keys - list of id's/paths that should be totalled */
/* Totals - possibly nested dict */
 table_totals(Rows, Keys, Totals) :-
	table_totals2(Rows, Keys, _{}, Totals).

table_totals2(Rows, [Key|Keys], In, Out) :-
	Mid = In.put(Key, Total),
	column_by_key(Rows, Key, Vals),
	sum_cells(Vals, Total),
	table_totals2(Rows, Keys, Mid, Out).

table_totals2(_Rows, [], Dict, Dict).


column_by_key(Rows, Key, Vals) :-
	findall(
		Val,
		(
		 member(Row, Rows),
		 path_get_dict(Key, Row, Val)
		),
		Vals
	).

sum_cells(Values, Sum) :-
	flatten(Values, Vec),
	vec_add(Vec, [], Sum).

		  

