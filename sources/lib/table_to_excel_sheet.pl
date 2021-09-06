/*

Generic conversion from our table format into a sheet. The sheet's type will be a bnode, or a pseudo-bnode. At any case it will not be possible to read it back, because the client does not store the template. The sheet data will be asserted in result_sheets_graph, and a "result_sheets" report entry will be created for a rdf file of that graph.

*/

/*
  <abstract representation of a table> to <excel sheet rdf>
*/


 'table sheet'(Table_Json0) :-
 	!stringify_table_cells(excel, Table_Json0, Table_Json),
	_{title_short: Title_Text_short, title: Title_Text, rows: Rows, columns: Columns} :< Table_Json,
	/* sheet instance */
	bn(result_sheet, Sheet_instance),
	bn(result_sheet_type, Sheet_type),
	bn(result_sheet_template_root, Template_root),

	!doc_add(Sheet_instance, excel:is_result_sheet, true, $>result_sheets_graph),
	!doc_add(Sheet_instance, excel:sheet_instance_has_sheet_name, Title_Text_short, $>result_sheets_graph),
	!doc_add(Sheet_instance, excel:sheet_instance_has_sheet_type, Sheet_type, $>result_sheets_graph),
	!doc_add(Sheet_type, excel:root, Template_root, $>result_sheets_graph),
	bn(result_template_position, Pos),
	!doc_add(Pos, excel:col, "A", $>result_sheets_graph),
	!doc_add(Pos, excel:row, "3", $>result_sheets_graph),
	!doc_add(Template_root, excel:position, Pos, $>result_sheets_graph),
	!doc_add(Template_root, excel:title, Title_Text, $>result_sheets_graph),
	!doc_add(Template_root, excel:cardinality, excel:multi, $>result_sheets_graph),
	bn(investment_report_item_type, Investment_report_item_type),
	!doc_add(Template_root, excel:class, Investment_report_item_type, $>result_sheets_graph),
	excel_template_fields_from_table_declaration(Columns, Fields, Column_id_to_prop_uri_dict),
	!doc_add(Template_root, excel:fields, $>doc_add_list(Fields, $>result_sheets_graph), $>result_sheets_graph),
	maplist(!'table sheet record'(Columns, Column_id_to_prop_uri_dict), Rows, Items),
	!doc_add_value(Sheet_instance, excel:sheet_instance_has_sheet_data, $>doc_add_list(Items, $>result_sheets_graph), $>result_sheets_graph).



/*
┏━┓╻ ╻┏━╸┏━╸╺┳╸   ╺┳╸╻ ╻┏━┓┏━╸
┗━┓┣━┫┣╸ ┣╸  ┃     ┃ ┗┳┛┣━┛┣╸
┗━┛╹ ╹┗━╸┗━╸ ╹ ╺━╸ ╹  ╹ ╹  ┗━╸
*/

 excel_template_fields_from_table_declaration(Columns, Fields, Prop_uri_dict) :-
	!maplist(column_fields('',""), Columns, Fields0, Group_ids, Prop_uri_dicts),
	column_or_group_id_to_uri_or_uridict(Group_ids, Prop_uri_dicts, Prop_uri_dict),
	flatten(Fields0, Fields).

 column_fields(Parent_group_uri, Prefix, Dict, Fields, Group_id, Prop_uri_dict) :-
 	group{id:Group_id, title:Group_title, members:Group_members} :< Dict,
	bn(column_group, G),
	doc_add(G, l:id, Group_id, $>result_sheets_graph),
	(	Parent_group_uri == ''
	->	true
	/* l:has_group won't be used in the end, but may be useful in future.. */
	;	doc_add(G, l:has_group, Parent_group_uri, $>result_sheets_graph)),
	group_prefix(Prefix, Group_title, Group_prefix),
	maplist(column_fields(Group_id, Group_prefix), Group_members, Fields, Ids, Prop_uris),
	column_or_group_id_to_uri_or_uridict(Ids, Prop_uris, Prop_uri_dict).

 column_fields(Group_uri, Group_prefix, Dict, Field, Id, Prop) :-
	column{id:Id} :< Dict,
	column_title(Dict, Group_prefix, Title),
	(	Group_uri == ''
	->	true
	;	doc_add(Field, l:has_group, Group_uri, $>result_sheets_graph)),
	/*
	here we generate an uri for prop, but we will have to use it when creating rows. Actually, we'll have to relate the non-unique(within the whole columns treee) id of a column to the prop uri, hence the asserted l:has_group tree of groups.
	*/
	bn(table_field, Field),
	doc_add(Field, excel:type, xsd:string, $>result_sheets_graph),
	bn(prop, Prop),
	doc_add(Prop, rdfs:label, Title, $>result_sheets_graph),
	doc_add(Field, excel:property, Prop, $>result_sheets_graph),
	doc_add(Prop, l:id, Id, $>result_sheets_graph).

 column_or_group_id_to_uri_or_uridict(Ids, Prop_uris, Prop_uri_dict) :-
	pairs_keys_values(Prop_uri_pairs, Ids, Prop_uris),
	dict_pairs(Prop_uri_dict, uris, Prop_uri_pairs).



/*
┏━┓╻ ╻┏━╸┏━╸╺┳╸   ╺┳┓┏━┓╺┳╸┏━┓
┗━┓┣━┫┣╸ ┣╸  ┃     ┃┃┣━┫ ┃ ┣━┫
┗━┛╹ ╹┗━╸┗━╸ ╹ ╺━╸╺┻┛╹ ╹ ╹ ╹ ╹
sheet_data
*/

 'table sheet record'(Cols, Props, Row, Record) :-
	debug(sheet_data, '~q', ['table sheet record'(Cols, Props, Row, Record)]),
	bn(sheet_record, Record),
	maplist(!'table sheet record 2'(Props, Row, Record), Cols).


 'table sheet record 2'(_Props, '', _, _) :- !.

 'table sheet record 2'(Props, Row, Record, Col) :-
	group{id: Id, members: Members} :< Col,
	get_dict(Id, Row, Subrow),
	get_dict(Id, Props, Subprops),
	maplist('table sheet record 2'(Subprops, Subrow, Record), Members).


 'table sheet record 2'(Props, Row, Record, Col) :-
	column{id: Id} :< Col,
	get_dict(Id, Props, Prop_uri),
	get_dict(Id, Row, Abstract),
	result_sheets_graph(Graph),
	!abstract_sheet_cell_value_to_excel((Record, Prop_uri, Graph), Abstract, _Uri).

 abstract_sheet_cell_value_to_excel((Record, Prop_uri, Graph), Cell, Uri) :-
 	Cell = date(_,_,_),
 	!,
 	/* this date/3 term will be automatically converted into xsd:date */
	doc_add_value2(Record, Prop_uri, Uri, Cell, Graph).

 abstract_sheet_cell_value_to_excel((Record, Prop_uri, Graph), Cell, Uri) :-
 	Cell = money(Lit),
 	!,
 	doc_add_value2(Record, Prop_uri, Uri, Lit, Graph),
 	/* excel's "accounting" format */
	doc_add(Uri, excel:suggested_display_format, "_-$* #,##0.00_-;-$* #,##0.00_-;_-$* \"-\"??_-;_-@_-", Graph).


 abstract_sheet_cell_value_to_excel((Record, Prop_uri, Graph), L, Uri) :-
 	/* if it's a list, we can only turn it into a string */
 	is_list(L),
 	flatten(L, L2),
 	!,
 	(	L2 = [E]
 	->	abstract_sheet_cell_value_to_excel((Record, Prop_uri, Graph), E, Uri)
 	;	(
 			abstract_sheet_cell_list_to_excel(L2, Str),
			doc_add_value2(Record, Prop_uri, Uri, Str, Graph)
		)
	).

 abstract_sheet_cell_value_to_excel((Record, Prop_uri, Graph), Cell, Uri) :-
	(
		(
			atom(Cell),
			atom_string(Cell, Str)
		)
		;
		(
			string(Cell),
			Str = Cell
		)
	),
	!,
	doc_add_value2(Record, Prop_uri, Uri, Str, Graph).

 abstract_sheet_cell_value_to_excel((Record, Prop_uri, Graph), Cell, Uri) :-
	is_numeric(Cell),
	!,
	doc_add_value2(Record, Prop_uri, Uri, Cell, Graph).

 abstract_sheet_cell_list_to_excel([H|T], Str) :-
 	pseudo_html_to_sheet_cell_string(H, Str1),
 	abstract_sheet_cell_list_to_excel(T, Str2),
 	atomics_to_string([Str1, '\n', Str2], Str).

 abstract_sheet_cell_list_to_excel([], "").



 pseudo_html_to_sheet_cell_string(Atom, Lit) :-
 	(Atom = date(_,_,_),format_date(Atom, Lit))
	;
	Atom = money(Lit)
	;
	atomic(Atom),atom_string(Atom,Lit)
	;
	Atom = link(_, Lit).


