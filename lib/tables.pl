
:- module('tables', []).

:- use_module('days').
:- use_module('utils').
:- use_module('pacioli').

:- use_module(library(rdet)).

/*
do cuts caused by the rdet ifs still cut into the findalling?
:- rdet(formatted_row_kvs/3).
:- rdet(group_columns/2).
:- rdet(format_column/3).
*/
:- rdet(table_totals/3).
:- rdet(table_html/2).
:- rdet(format_row/3).
:- rdet(row_to_html/3).

/*
  <internal representation of ... whatever> to <html something>
  Table - internal representation of whatever
  second argument - something html
*/ 
table_html(
	Table, 
	/*[div([span([Table.title, ':']), HTML_Table])]*/
	HTML_Table
) :-
	format_table(Table, Formatted_Table),
	table_contents_to_html(Formatted_Table, HTML_Table).

/*
  this one converts the actual tabular data in the report to an
  actual html table
  first argument - internal representation of tabular data, formatted into strings, flat?
  second argument - html_write table term/input
  
*/
table_contents_to_html(
	table{title:_, columns: Columns, rows: Rows},
	[HTML_Header | HTML_Rows_Highlighted]
	/*table([border="1"],[HTML_Header | HTML_Rows])*/
) :-
	header_html(Columns, HTML_Header),
	rows_to_html(Columns, Rows, HTML_Rows),
	highlight_totals(HTML_Rows,HTML_Rows_Highlighted).

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

column_header_html(column{id:_, title:Column_Title, options:Options}, Prefix, th(Header_Value)) :-
	(
		(Prefix = "" ; get_dict(hide_group_prefix, Options, true))
	->
		Header_Value = Column_Title
	;
		atomics_to_string([Prefix, Column_Title], " ", Header_Value)
	).

row_to_html(Columns, Row, HTML_Row) :-
	findall(
		Cells,
		(
			member(Column, Columns),
			column_to_html(Column, Row.(Column.id), Cells)
		),
		HTML_Row
	).

/*
column_to_html(group{id:_, title:_, members:Group_Members}, '', Cells) :-
	!,
	blank_row(Group_Members, Cells).
*/

column_to_html(group{id:Group_ID, title:Group_Title, members:Group_Members}, Row, Cells) :-
	(
		Row = ''
	->
		blank_row(group{id:Group_ID, title:Group_Title, members:Group_Members}, Cells)
	;
		row_to_html(Group_Members, Row, Cells)
	).

column_to_html(column{id:_, title:_, options:_}, Cell, [td(Cell_Flat)]) :-
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

blank_row(column{id:_, title:_, options:_}, [td("")]). % :-
	/*atomics_to_string([Column_ID, "Blank"], ": ", Cell_Value).*/
	

format_table(
	table{title:Title, columns:Columns, rows:Rows}, 
	table{title:Title, columns:Columns, rows:Formatted_Rows}
) :-
	maplist(format_row(Columns),Rows,Formatted_Rows).


format_row(Columns, Row, Formatted_Row) :-
	findall(KV, formatted_row_kvs(Columns, Row, KV), Formatted_Row_KVs),
	dict_create(Formatted_Row,row,Formatted_Row_KVs).

formatted_row_kvs(Columns, Row, KV) :-
	member(Column, Columns),
	(
		get_dict(Column.id, Row, _)
	->
		format_column(Column, Row, KV)
	;
		KV = (Column.id):''
	).

format_column(group{id:Column_ID, title:_, members:Group_Members}, Row, Column_ID:Formatted_Group) :-
	format_row(Group_Members, Row.Column_ID, Formatted_Group).

format_column(column{id:Column_ID, title:_, options:Column_Options}, Row, Column_ID:Formatted_Cell) :-
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
		column{
			id:Group_ID/Member_ID,
			title:Column_Title,
			options:Options
		},
		(
			member(column{id:Member_ID, title:Member_Title, options:Options}, Group_Members),
			atomics_to_string([Group_Title, Member_Title], " ", Column_Title)
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
	
format_cell(value(Unit, Value), Options, Output) :-
	(
		Precision = Options.get(precision)
	->
		true
	;
		Precision = 2
	),
	format_money2(_, Precision, value(Unit, Value), Output),
	!.

format_cell(exchange_rate(Date, Src, Dst, Rate), _, Output) :-
	format_conversion(_, exchange_rate(Date, Src, Dst, Rate), Output),
	!.

format_cell(Other, _, Other) :-
	atom(Other),!.

format_cell(Other, _, Str) :-
	term_string(Other, Str).


format_money_precise(Optional_Implicit_Unit, In, Out) :-
	format_money2(Optional_Implicit_Unit, 6, In, Out).
	
format_money(Optional_Implicit_Unit, In, Out) :-
	format_money2(Optional_Implicit_Unit, 2, In, Out).

format_money2(_Optional_Implicit_Unit, Precision, In, Out) :-
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
			false%member(Unit1, Optional_Implicit_Unit)
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
/* Keys - list of id's that should be totalled */
/* Totals - possibly nested dict */
table_totals(Rows, Keys, Totals) :-
	table_totals2(Rows, Keys, _{}, Totals).

table_totals2(Rows, [Key|Keys], In, Out) :-
	Mid = In.put(Key, Total),
	column_by_key(Rows, Key, Vals),
	sum_cells(Vals, Total),
	%print_term(table_totals2('rrrr', Rows, 'vvvvv', Total, Key, In, Mid), []),
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

		  

