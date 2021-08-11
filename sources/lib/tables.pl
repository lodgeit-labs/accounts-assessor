/*
  <abstract representation of a table> to <html something>
*/
 table_html(
	Options,
	Table, 
	/*[div([span([Table.title, ':']), HTML_Table])]*/
	HTML_Table
) :-
	format_table_rows(Table, Formatted_Table),
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
	findall(
		tr(Row_Flat),
		(
			member(Row, Html1),
			flatten(Row, Row_Flat)
		),
		Html3
	).


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

 sheet_fields(Columns, Fields, Prop_uri_dict) :-
	maplist('', column_fields(""), Columns, Fields0, Group_ids, Prop_uri_dicts),
	column_or_group_id_to_uri_or_uridict(Group_ids, Prop_uri_dicts, Prop_uri_dict) :-
	flatten(Fields0, Fields).

 column_fields(Parent_group_uri,Prefix, Dict, Fields, Group_id, Prop_uri_dict) :-
 	group{id:Group_id, title:Group_title, members:Group_members} :< Dict,
	bn(column_group, G),
	doc_add(G, l:id, Id),
	(	Parent_group_uri == ''
	->	''
	;	doc_add(G, l:has_group, Parent_group_uri)),
	group_prefix(Prefix, Group_title, Group_prefix),
	maplist(column_fields(G, Group_id, Group_prefix), Group_members, Fields, Ids, Prop_uris),
	column_or_group_id_to_uri_or_uridict(Ids, Prop_uris, Prop_uri_dict).

 column_or_group_id_to_uri_or_uridict(Ids, Prop_uris, Prop_uri_dict) :-
	pairs_keys_values(Prop_uri_pairs, Ids, Prop_uris),
	dict_pairs(Prop_uri_dict, uris, Prop_uri_pairs).

 column_fields(Group_uri, Group_prefix, Dict, Field, Id, Prop) :-
	column{id:Id} :< Dict,
	column_title(Dict, Prefix, Title),
	(	Group_uri == ''
	->	''
	;	doc_add(Field, l:has_group, Group_uri)),
	/*
	here we generate an uri for prop, but we will have to use it when creating rows. Actually, we'll have to relate the non-unique(within the whole columns treee) id of a column to the prop uri, hence the asserted l:has_group tree of groups.
	*/
	bn(table_field, Field),
	doc_add(F, excel:type, xsd:string),
	bn(prop, Prop),
	doc_add(Prop, rdfs:label, Title),
	doc_add(F, excel:property, Prop),
	doc_add(Prop, l:id, Id).

 prop_uri_dict(Fields, Prop_uris, Prop_uri_dict) :-
 	findall(
 		V,
 		(
 			member(Field, Fields),
 			Field.id


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

		  


