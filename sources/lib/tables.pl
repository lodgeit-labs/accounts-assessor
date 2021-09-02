/*
  <abstract representation of a table> to <html something>
*/
 table_html(
	Options,
	Table, 
	/*[div([span([Table.title, ':']), HTML_Table])]*/
	HTML_Table
) :-
	!stringify_table_cells(html, Table, Formatted_Table),
	!table_to_html(Options, Formatted_Table, HTML_Table).






/*
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
			%is_dict(Column, column),
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
*/



/*
╺┳╸┏━┓╺┳╸┏━┓╻  ┏━┓
 ┃ ┃ ┃ ┃ ┣━┫┃  ┗━┓
 ╹ ┗━┛ ╹ ╹ ╹┗━╸┗━┛

produce an additional row with totals, calculated from Rows, directed by Keys.

*/


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
	vec_reduce(Vec, Sum).
