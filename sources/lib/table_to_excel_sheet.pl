/*

Generic conversion from our table format into a sheet. The sheet's type will be a bnode, or a pseudo-bnode. At any case it will not be possible to read it back, because the client does not store the template. The sheet data will be asserted in result_sheets_graph, and a "result_sheets" report entry will be created for a rdf file of that graph.

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

	!doc_add(Sheet_instance, excel:is_result_sheet, true, $>result_sheets_graph),
	!doc_add(Sheet_instance, excel:sheet_instance_has_sheet_type, Sheet_type, $>result_sheets_graph),
	!doc_add(Sheet_type, excel:root, Template_root, $>result_sheets_graph),
	bn(result_template_position, Pos),
	!doc_add(Pos, excel:col, "A", $>result_sheets_graph),
	!doc_add(Pos, excel:row, "3", $>result_sheets_graph),
	!doc_add(Sheet_type, excel:position, Pos, $>result_sheets_graph),
	!doc_add(Sheet_type, excel:title, Title_Text, $>result_sheets_graph),
	!doc_add(Sheet_type, excel:cardinality, excel:multi, $>result_sheets_graph),
	bn(investment_report_item_type, Investment_report_item_type),
	!doc_add(Sheet_type, excel:class, Investment_report_item_type, $>result_sheets_graph),
	excel_template_fields_from_table_declaration(Columns, Fields, Column_id_to_prop_uri_dict),
	!doc_add(Sheet_type, excel:fields, $>doc_add_list(Fields, $>result_sheets_graph), $>result_sheets_graph),
	maplist('table sheet record'(Columns, Column_id_to_prop_uri_dict), Rows, Items),
	!doc_add_value(Sheet_instance, excel:sheet_instance_has_sheet_data, $>doc_add_list(Items, $>result_sheets_graph), $>result_sheets_graph).



/*
┏━┓╻ ╻┏━╸┏━╸╺┳╸   ╺┳╸╻ ╻┏━┓┏━╸
┗━┓┣━┫┣╸ ┣╸  ┃     ┃ ┗┳┛┣━┛┣╸
┗━┛╹ ╹┗━╸┗━╸ ╹ ╺━╸ ╹  ╹ ╹  ┗━╸
*/

 excel_template_fields_from_table_declaration(Columns, Fields, Prop_uri_dict) :-
	maplist(column_fields('',""), Columns, Fields0, Group_ids, Prop_uri_dicts),
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
	doc_add(F, excel:type, xsd:string, $>result_sheets_graph),
	bn(prop, Prop),
	doc_add(Prop, rdfs:label, Title, $>result_sheets_graph),
	doc_add(F, excel:property, Prop, $>result_sheets_graph),
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

 'table sheet record'(Cols, Props, Row, Item) :-
	debug(sheet_data, '~q', ['table sheet record'(Cols, Props, Row, Item)]),
	bn(sheet_record, Record),
	maplist( 'table sheet record 2'(Props, Row, Record), Cols).


 'table sheet record 2'(Props, Row, Record, Col) :-
	group{id: Id, members: Members} :< Col,
	Row.get(Id, Subrow),
	Props.get(id, Subprops),
	maplist('table sheet record 2'(Subprops, Subrow, Record), Members).


 'table sheet record 2'(Props, Row, Record, Col) :-
	column{id: Id} :< Col,
	Props.get(Id, Prop_uri),
	Row.get(Id, Value_atom),
	atom_string(Value_atom, Value),
	doc_add_value(Record, Prop_uri, Value, $>result_sheets_graph).

/*


Cols =
[ column{id:unit,options:_{},title:"Unit"},
  column{id:count,options:_{},title:"Count"},
  column{id:currency,options:_{},title:"Investment Currency"},
  group{ id:purchase,
	 members:[ column{id:date,options:A{},title:"Date"},
		   column{ id:unit_cost_foreign,
			   options:B{},
			   title:"Unit Cost Foreign"
			 },
		   column{ id:conversion,
			   options:C{},
			   title:"Conversion"
			 },
		   column{ id:unit_cost_converted,
			   options:D{},
			   title:"Unit Cost Converted"
			 },
		   column{ id:total_cost_foreign,
			   options:E{},
			   title:"Total Cost Foreign"
			 },
		   column{ id:total_cost_converted,
			   options:F{},
			   title:"Total Cost Converted"
			 }
		 ],
	 title:"Purchase"
       },
  group{ id:opening,
	 members:[ column{id:date,options:G{},title:"Date"},
		   column{ id:unit_cost_foreign,
			   options:H{},
			   title:"Unit Value Foreign"
			 },
		   column{ id:conversion,
			   options:I{},
			   title:"Conversion"
			 },
		   column{ id:unit_cost_converted,
			   options:J{},
			   title:"Unit Value Converted"
			 },
		   column{ id:total_cost_foreign,
			   options:K{},
			   title:"Total Value Foreign"
			 },
		   column{ id:total_cost_converted,
			   options:L{},
			   title:"Total Value Converted"
			 }
		 ],
	 title:"Opening"
       },
  group{ id:sale,
	 members:[ column{id:date,options:A{},title:"Date"},
		   column{ id:unit_cost_foreign,
			   options:B{},
			   title:"Unit Cost Foreign"
			 },
		   column{ id:conversion,
			   options:C{},
			   title:"Conversion"
			 },
		   column{ id:unit_cost_converted,
			   options:D{},
			   title:"Unit Cost Converted"
			 },
		   column{ id:total_cost_foreign,
			   options:E{},
			   title:"Total Cost Foreign"
			 },
		   column{ id:total_cost_converted,
			   options:F{},
			   title:"Total Cost Converted"
			 }
		 ],
	 title:"Sale"
       },
  group{ id:closing,
	 members:[ column{id:date,options:G{},title:"Date"},
		   column{ id:unit_cost_foreign,
			   options:H{},
			   title:"Unit Value Foreign"
			 },
		   column{ id:conversion,
			   options:I{},
			   title:"Conversion"
			 },
		   column{ id:unit_cost_converted,
			   options:J{},
			   title:"Unit Value Converted"
			 },
		   column{ id:total_cost_foreign,
			   options:K{},
			   title:"Total Value Foreign"
			 },
		   column{ id:total_cost_converted,
			   options:L{},
			   title:"Total Value Converted"
			 }
		 ],
	 title:"Closing"
       },
  group{ id:on_hand_at_cost,
	 members:[ column{ id:unit_cost_foreign,
			   options:_{},
			   title:"Foreign Per Unit"
			 },
		   column{id:count,options:_{},title:"Count"},
		   column{ id:total_foreign,
			   options:_{},
			   title:"Foreign Total"
			 },
		   column{ id:total_converted_at_purchase,
			   options:_{},
			   title:"Converted at Purchase Date Total"
			 },
		   column{ id:total_converted_at_balance,
			   options:_{},
			   title:"Converted at Balance Date Total"
			 },
		   column{ id:total_forex_gain,
			   options:_{},
			   title:"Currency Gain/(loss) Total"
			 }
		 ],
	 title:"On Hand At Cost"
       },
  group{ id:gains,
	 members:[ group{ id:rea,
			  members:[ column{ id:market_foreign,
					    options:M{},
					    title:"Market Gain Foreign"
					  },
				    column{ id:market_converted,
					    options:N{},
					    title:"Market Gain Converted"
					  },
				    column{ id:forex,
					    options:O{},
					    title:"Forex Gain"
					  }
				  ],
			  title:"Realized"
			},
		   group{ id:unr,
			  members:[ column{ id:market_foreign,
					    options:M{},
					    title:"Market Gain Foreign"
					  },
				    column{ id:market_converted,
					    options:N{},
					    title:"Market Gain Converted"
					  },
				    column{ id:forex,
					    options:O{},
					    title:"Forex Gain"
					  }
				  ],
			  title:"Unrealized"
			}
		 ],
	 title:""
       }
]

Props =
uris{ closing:uris{ conversion:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12559_prop',
		    date:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12555_prop',
		    total_cost_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12565_prop',
		    total_cost_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12563_prop',
		    unit_cost_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12561_prop',
		    unit_cost_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12557_prop'
		  },
      count:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12511_prop',
      currency:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12513_prop',
      gains:uris{ rea:uris{ forex:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12586_prop',
			    market_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12584_prop',
			    market_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12582_prop'
			  },
		  unr:uris{ forex:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12593_prop',
			    market_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12591_prop',
			    market_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12589_prop'
			  }
		},
      on_hand_at_cost:uris{ count:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12570_prop',
			    total_converted_at_balance:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12576_prop',
			    total_converted_at_purchase:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12574_prop',
			    total_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12572_prop',
			    total_forex_gain:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12578_prop',
			    unit_cost_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12568_prop'
			  },
      opening:uris{ conversion:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12533_prop',
		    date:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12529_prop',
		    total_cost_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12539_prop',
		    total_cost_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12537_prop',
		    unit_cost_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12535_prop',
		    unit_cost_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12531_prop'
		  },
      purchase:uris{ conversion:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12520_prop',
		     date:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12516_prop',
		     total_cost_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12526_prop',
		     total_cost_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12524_prop',
		     unit_cost_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12522_prop',
		     unit_cost_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12518_prop'
		   },
      sale:uris{ conversion:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12546_prop',
		 date:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12542_prop',
		 total_cost_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12552_prop',
		 total_cost_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12550_prop',
		 unit_cost_converted:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12548_prop',
		 unit_cost_foreign:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12544_prop'
	       },
      unit:'http://dev-node.uksouth.cloudapp.azure.com/rdf/results/1630007668.103844.7.3.366FDD1x14860/#bnx12509_prop'
    }

Row =
row{ closing:row{ conversion:"1AUD=0.716776CHF",
		  date:"2021-03-31",
		  total_cost_converted:[class=money_amount]div["76,732.51AUD"],
		  total_cost_foreign:[class=money_amount]div["55,000.00CHF"],
		  unit_cost_converted:[class=money_amount]div["1.40AUD"],
		  unit_cost_foreign:[class=money_amount]div["1.00CHF"]
		},
     count:"55000",
     currency:'CHF',
     gains:row{ rea:row{forex:'',market_converted:'',market_foreign:''},
		unr:row{ forex:[class=money_amount]div["-6,621.24AUD"],
			 market_converted:[class=money_amount]div["0.00AUD"],
			 market_foreign:[class=money_amount]div["0.00CHF"]
		       }
	      },
     on_hand_at_cost:row{ count:"55000",
			  total_converted_at_balance:[ (class=money_amount)
						     ]div["76,732.51AUD"],
			  total_converted_at_purchase:[ (class=money_amount)
						      ]div["79,183.66AUD"],
			  total_foreign:[class=money_amount]div["55,000.00CHF"],
			  total_forex_gain:[class=money_amount]div["-2,451.14AUD"],
			  unit_cost_foreign:[class=money_amount]div["1.00CHF"]
			},
     opening:row{ conversion:"1AUD=0.659838CHF",
		  date:"2020-09-30",
		  total_cost_converted:[class=money_amount]div["83,353.76AUD"],
		  total_cost_foreign:[class=money_amount]div["55,000.00CHF"],
		  unit_cost_converted:[class=money_amount]div["1.52AUD"],
		  unit_cost_foreign:[class=money_amount]div["1.00CHF"]
		},
     purchase:row{ conversion:'',
		   date:'',
		   total_cost_converted:'',
		   total_cost_foreign:'',
		   unit_cost_converted:'',
		   unit_cost_foreign:''
		 },
     sale:row{ conversion:'',
	       date:'',
	       total_cost_converted:'',
	       total_cost_foreign:'',
	       unit_cost_converted:'',
	       unit_cost_foreign:''
	     },
     unit:'3% CT1 Issuer Limited'
   }





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
