/*

Generic conversion from our table format into a sheet. The sheet's type will be a bnode, or a pseudo-bnode. At any case it will not be possible to read it back, because the client does not store the template. The sheet data will be asserted in 'sheets' graph, and a "result_sheets" report entry will be created for a rdf file of that graph.

*/

/*
  <abstract representation of a table> to <excel sheet rdf>
*/


 'table sheet'(Table_Json0) :-
 	stringify_table_cells(Table_Json0, Table_Json),
	Table_Json = _{title: Title_Text, rows: Rows, columns: Columns},

	/* sheet instance */
	bn(result_sheet, Sheet_instance),
	bn(result_sheet_type, Sheet_type),
	bn(result_sheet_template_root, Template_root),

	!doc_add(Sheet_instance, excel:is_result_sheet, true),
	!doc_add(Sheet_instance, excel:sheet_instance_has_sheet_type, Sheet_type),
	!doc_add(Sheet_type, excel:root, Template_root),
	bn(result_template_position, Pos),
	!doc_add(Pos, excel:col "A"),
	!doc_add(Pos, excel:row "3"),
	!doc_add(Sheet_type, excel:position, Pos),
	!doc_add(Sheet_type, excel:title, Title_Text),
	!doc_add(Sheet_type, excel:cardinality, excel:multi),
	bn(investment_report_item_type, Investment_report_item_type),
	!doc_add(Sheet_type, excel:class, Investment_report_item_type),
	excel_template_fields_from_table_declaration(Columns, Fields, Column_id_to_prop_uri_dict),
	!doc_add(Sheet_type, excel:fields, $>doc_add_list(Fields)),
	maplist('table sheet record'(Columns), Rows, Items),
	!doc_add_value(Sheet_instance, excel:sheet_instance_has_sheet_data, $>doc_add_list(Items)).



/*
┏━┓╻ ╻┏━╸┏━╸╺┳╸   ╺┳╸╻ ╻┏━┓┏━╸
┗━┓┣━┫┣╸ ┣╸  ┃     ┃ ┗┳┛┣━┛┣╸
┗━┛╹ ╹┗━╸┗━╸ ╹ ╺━╸ ╹  ╹ ╹  ┗━╸
*/

 excel_template_fields_from_table_declaration(Columns, Fields, Prop_uri_dict) :-
	maplist('', column_fields(""), Columns, Fields0, Group_ids, Prop_uri_dicts),
	column_or_group_id_to_uri_or_uridict(Group_ids, Prop_uri_dicts, Prop_uri_dict) :-
	flatten(Fields0, Fields).

 column_fields(Parent_group_uri,Prefix, Dict, Fields, Group_id, Prop_uri_dict) :-
 	group{id:Group_id, title:Group_title, members:Group_members} :< Dict,
	bn(column_group, G),
	doc_add(G, l:id, Id),
	(	Parent_group_uri == ''
	->	''
	/* l:has_group won't be used in the end, but may be useful in future.. */
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



/*
┏━┓╻ ╻┏━╸┏━╸╺┳╸   ╺┳┓┏━┓╺┳╸┏━┓
┗━┓┣━┫┣╸ ┣╸  ┃     ┃┃┣━┫ ┃ ┣━┫
┗━┛╹ ╹┗━╸┗━╸ ╹ ╺━╸╺┻┛╹ ╹ ╹ ╹ ╹
sheet_data
*/

 'table sheet record'(Cols, Row, Item) :-
	%pairs_keys_values(Prop_uri_pairs, Ids, Prop_uris),
	gtrace,
	debug(sheet_data, '~q', ['table sheet record'(Cols, Row, Item)]).






/*
	excel:fields (
		[excel:property av:name; excel:type xsd:string]
		[excel:property av:exchanged_account; excel:type xsd:string]
		[excel:property av:trading_account; excel:type xsd:string]
		[excel:property av:description; excel:type xsd:string]
		[excel:property av:gst_receivable_account; excel:type xsd:string]
		[excel:property av:gst_payable_account; excel:type xsd:string]
		[excel:property av:gst_rate_percent; excel:type xsd:string]
	).

	Columns = [
		column{id:unit_cost_foreign, 			title:"Foreign Per Unit", options:_{}},
		column{id:count, 						title:"Count", options:_{}},
		column{id:total_foreign, 				title:"Foreign Total", options:_{}},
		column{id:total_converted_at_purchase, 	title:"Converted at Purchase Date Total", options:_{}},
		column{id:total_converted_at_balance, 	title:"Converted at Balance Date Total", options:_{}},
		column{id:total_forex_gain, 			title:"Currency Gain/(loss) Total", options:_{}}
	],



*/
