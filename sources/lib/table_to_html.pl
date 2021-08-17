/*
  this one converts the stringified tabular data in the report to html
  first argument - internal representation of tabular data, formatted into strings, flat?
  second argument - html_write table term/input

*/
 table_to_html(
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
	findall(
		tr(Row_Flat),
		(
			member(Row, Html1),
			flatten(Row, Row_Flat)
		),
		Html3
	).


/*
given a dict of column declarations, and a dict of strings/html tags, produce a list of td tags
*/

 row_to_html(Columns, Row, HTML_Row) :-
	findall(
		Cell,
		(
			member(Column, Columns),
			(	get_dict(id, Column, Column_id)
			->	!dict_to_cells(Column, Row.Column_id, Cell)
			;	Cell = [td([""])])
		),
		HTML_Row
	).

 dict_to_cells(Group, Data, Cells) :-
 	group{id:Group_ID, title:Group_Title, members:Group_Members} :< Group,
	(
		Data = ''
	->
		blank_row(Group, Cells)
	;
		dict_to_cells(Group_Members, Data, Cells)
	).

 dict_to_cells(Dict, Cell, [td(Cell_Flat)]) :-
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



highlight_totals([Row1, Row2 | Rows], [Row1 | Highlighted]) :-
	highlight_totals([Row2 | Rows], Highlighted).

highlight_totals([tr(Row)], [tr([style="background-color:#DDDDEE; font-weight:bold"],Row)]).


 column_title(Dict, Prefix, Header_value) :-
	column{title: Column_title, options: Options} :< Dict,
	(	(Prefix = "" -> true ; get_dict(hide_group_prefix, Options, true))
	->	Header_value = Column_title
	;	atomics_to_string([Prefix, Column_title], " ", Header_value)).

 group_prefix(Prefix, Group_title, Group_prefix) :-
	(	Prefix = ""
	->	Group_prefix = Group_title
	;	atomics_to_string([Prefix, Group_title], " ", Group_prefix)).


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

 column_header_html(Dict, Prefix, Cells) :-
 	group{title:Group_title, members:Group_members} :< Dict,
	group_prefix(Prefix, Group_title, Group_prefix),
	findall(
		Child_cells,
		(
			member(Column, Group_members),
			column_header_html(Column, Group_prefix, Child_cells)
		),
		Cells
	).

 column_header_html(Dict, Prefix, th(Header_Value)) :-
	column_title(Dict, Prefix, Header_value).
