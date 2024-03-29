
 smsf_member_reports(Report_prefix,Json_reports) :-
	!smsf_members_throw(Members),
	Json_reports2 = _{final:Json_reports},
	!maplist(!smsf_member_report(Report_prefix,Json_reports2), Members, _Json).


 smsf_member_report(Report_prefix,Json_reports, Member_uri, _{overview:Tbl1, details:Tbl2}) :-
	!doc_value(Member_uri, smsf:member_name, Member_Name_str),
	!atom_string(Member_atom, Member_Name_str),
	!smsf_member_details_report(Json_reports, Member_atom, Tbl2),
	!smsf_member_overview_report(Member_atom, Tbl1),
	page_with_body(Member_Name_str, [
		Member_Name_str, ':', p([]),
		table([border="1"], $>table_html([], Tbl1)),
		p([]),
		table([border="1"], $>table_html([highlight_totals - true], Tbl2))
	], Html),
	atomic_list_concat('smsf_member_', Member_Name_str, Fn),
	add_report_page(
		0,
		Fn,
		Html,
		loc(file_name, $>atomic_list_concat([Report_prefix, smsf_member_, $>replace_nonalphanum_chars_with_underscore(Fn), '.html'])),
		'smsf_member_report'
	).

smsf_member_details_report(Json_reports, Member_atom, Tbl_dict) :-
	!smsf_member_report_presentation(Pres),
	!add_aspect_to_table(member - Member_atom, Pres, Pres3),
	!add_smsf_member_details_report_facts(Json_reports, Member_atom),
	!evaluate_fact_table(Pres3, Tbl),
	!maplist(smsf_member_report_row_to_dict, Tbl, Rows),
	Columns = [
		column{id:label, title:"Your Detailed Account", options:_{}},
		column{id:'Preserved', title:"Preserved", options:_{implicit_report_currency:true}},
		column{id:'Restricted_Non_Preserved', title:"Restricted_Non_Preserved", options:_{implicit_report_currency:true}},
		column{id:'Unrestricted_Non_Preserved', title:"Unrestricted_Non_Preserved", options:_{implicit_report_currency:true}},
		column{id:'Total', title:"Total", options:_{implicit_report_currency:true}}],
	Tbl_dict = table{title:Member_atom, columns:Columns, rows:Rows}.

smsf_member_overview_report(Member, Tbl_dict) :-
	Pres = [
		[text('Total Benefits'),
			aspects([
				concept - smsf/member/derived/'total',
				member - Member])],

		[text('Comprising:'),text('')],

		[text(' - Preserved'),
			aspects([
				concept - smsf/member/gl/_,
				phase - 'Preserved',
				member - Member])],

		[text('_-_Unrestricted_Non_Preserved'),
			aspects([
				concept - smsf/member/gl/_,
				phase - 'Unrestricted_Non_Preserved',
				member - Member])],

		[text('_-_Restricted_Non_Preserved'),
			aspects([
				concept - smsf/member/gl/_,
				phase - 'Restricted_Non_Preserved',
				member - Member])],

		[text('Including:'),text('')],

		[text(' - Tax-Free Component'),
			aspects([
				concept - smsf/member/gl/_,
				taxability - 'Tax-Free',
				member - Member])],

		[text(' - Taxable Component'),
			aspects([
				concept - smsf/member/gl/_,
				taxability - 'Taxable',
				member - Member])]
	],
	!evaluate_fact_table(Pres, Tbl),
	maplist(!label_value_row_to_dict, Tbl, Rows),
	Columns = [
		column{id:label, title:"Your Balance", options:_{}},
		column{id:value, title:"", options:_{implicit_report_currency:true}}],
	Tbl_dict = table{title:Member, columns:Columns, rows:Rows}.


 label_value_row_to_dict([A,B], Dict) :-
	Dict = row{
		label:A,
		value:B}.


 smsf_member_report_row_to_dict(Row, Dict) :-
	Row = [A,B,C,D,E],
	Dict = row{
		label:A,
		'Preserved':B,
		'Restricted_Non_Preserved':C,
		'Unrestricted_Non_Preserved':D,
		'Total':E}.


