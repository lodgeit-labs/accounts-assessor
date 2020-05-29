/*

resources:

https://www.taxandsuperaustralia.com.au/TSA/Members/SMSF_Toolkit.aspx#Sample
https://sf360.zendesk.com/hc/en-au/articles/360018366011-Create-Entries-Report
https://sf360.zendesk.com/hc/en-au/articles/360017821211-The-Create-Entries-Process

*/

 smsf_members_throw(Members) :-
	request_data(D),
	doc_value(D, smsf:members, List),
	doc_list_items(List, Members),
	(	Members = []
	->	throw_string('no SMSF members defined')
	;	true).
/*
 smsf_member_name_atoms_throw(Members) :-
 	smsf_members_throw(Members),
 	maplist(smsf_member_name_atoms, Members, Names),
 	maplist($>atom_string(<$

smsf_member_name_atoms(Member, Name) :-
*/

/*

phase 1 - setting up opening balances
	use quasi bank sheet to populate investments.
		action verb: Invest_In
		price: 0
		their value given by opening market values ends up in HistoricalEarnings
	use GL_input to clear out HistoricalEarnings into member opening balances.

	PL is always computed just for current period. Old transactions stay there but are not taken into account. At end of period, total of PL is copied over to retaine

*/


 extract_smsf_distribution(Txs) :-
  	!request_data(Rd),
 	(	doc(Rd, smsf:distribution, D)
 	->	!extract_smsf_distribution2(D, Txs)
 	;	Txs=[]).

 extract_smsf_distribution2(Distribution, Txs) :-
	!doc_value(Distribution, smsf_distribution_ui:default_currency, Default_currency0),
	!atom_string(Default_currency, Default_currency0),
	!doc_value(Distribution, smsf_distribution_ui:items, D),
	!doc_list_items(D, Items),
	!maplist(extract_smsf_distribution3(Default_currency), Items, Txs0),
 	!flatten(Txs0, Txs).

extract_smsf_distribution3(Default_currency, Item, Txs) :-
	doc_value(Item, smsf_distribution_ui:name, Unit_name_str),
	trim_string(Unit_name_str, Unit_name_str2),
	extract_smsf_distribution4(Default_currency, Item, Unit_name_str2, Txs).

extract_smsf_distribution4(_, _, "Dr/Cr", []) :- !.
extract_smsf_distribution4(_, _, "Total", []) :- !.

extract_smsf_distribution4(Default_currency, Item, Unit_name_str, Txs) :-
	!atom_string(Unit, Unit_name_str),
	!traded_units($>request_has_property(l:bank_s_transactions), Traded_Units),
	(	member(Unit, Traded_Units)
	->	true
	;	throw_string(['smsf distribution sheet: unknown unit: ', Unit])),
	!request_has_property(l:end_date, End_Date),
	!maplist(!smsf_distribution_tx(Default_currency, End_Date, Item),
		[dist{
			prop: smsf_distribution_ui:accrual,
			a:'Distribution Received'/Unit,
			dir:crdr,
			b:'Distribution Receivable'/Unit,
			desc:"Distributions Accrual entry as per Annual tax statements"},
		dist{
			prop: smsf_distribution_ui:foreign_credit,
			a:'Distribution Received'/Unit,
			dir:crdr,
			b:'Foreign And Other Tax Credits',
			desc:"Tax offset entry against distribution"},
		dist{
			prop: smsf_distribution_ui:franking_credit,
			a:'Distribution Received'/Unit,
			dir:crdr,
			b:'Imputed Credits',
			desc:"Tax offset entry against distribution"}
		],
		Txs).



smsf_distribution_tx(Default_currency, Date, Item, Dist, Txs) :-
	Dist = dist{prop:Prop, a:A, b:B, dir: crdr, desc:Desc},
	(	doc_value(Item, Prop, Amount_string)
	->	(
			(	vector_from_string(Default_currency, kb:credit, Amount_string, VectorA)
			->	true
			;	throw_string(['error reading "amount" in ', $>!sheet_and_cell_string($>doc(Item, Prop))])),
			!vec_inverse(VectorA, VectorB),
			!doc_new_uri(distributions_input_st, St),
			!doc_add_value(St, transactions:description, Desc, transactions),
			!doc_add_value(St, transactions:input_sheet_item, Item, transactions),
			Txs = [
				($>make_transaction(St, Date, Desc, $>!abrlt(A), VectorA)),
				($>make_transaction(St, Date, Desc, $>!abrlt(B), VectorB))
			]
		)
	;	Txs = []).


sheet_and_cell_string_for_property(Item, Prop, Str) :-
	!doc(Item, Prop, Value),
	!sheet_and_cell_string(Value, Str).

sheet_and_cell_string(Value, Str) :-
	!doc(Value, excel:sheet_name, Sheet_name),
	!doc(Value, excel:col, Col),
	!doc(Value, excel:row, Row),
	!atomics_to_string([Sheet_name, ' ', Col, ':', Row], Str).



smsf_member_reports(Bs) :-
	!smsf_members_throw(Members),
	!maplist(!smsf_member_report(Bs), Members).

 smsf_member_report(Bs, Member_uri) :-
	!doc_value(Member_uri, smsf:member_name, Member_Name_str),
	!atom_string(Member, Member_Name_str),
	!smsf_member_report_presentation(Pres),
	!add_aspect(member - Member, Pres, Pres3),
	%gtrace,
	!add_smsf_member_report_facts(Bs, Member),
	!evaluate_fact_table(Pres3, Tbl),
	maplist(smsf_member_report_row_to_dict, Tbl, Rows),
	Columns = [
		column{id:label, title:"Your Detailed Account", options:_{}},
		column{id:'Preserved', title:"Preserved", options:_{implicit_report_currency:true}},
		column{id:'Restricted Non Preserved', title:"Restricted Non Preserved", options:_{implicit_report_currency:true}},
		column{id:'Unrestricted Non Preserved', title:"Unrestricted Non Preserved", options:_{implicit_report_currency:true}},
		column{id:'Total', title:"Total", options:_{implicit_report_currency:true}}],
	Tbl_dict = table{title:Member_Name_str, columns:Columns, rows:Rows},
	table_html(Tbl_dict, Tbl_html),
	add_report_page_with_table(0, Member_Name_str, Tbl_html, loc(file_name, $>atomic_list_concat([$>replace_nonalphanum_chars_with_underscore(Member_Name_str), '.html'])), 'smsf_member_report').

smsf_member_report_row_to_dict(Row, Dict) :-
	Row = [A,B,C,D,E],
	Dict = row{
		label:A,
		'Preserved':B,
		'Restricted Non Preserved':C,
		'Unrestricted Non Preserved':D,
		'Total':E}.

add_smsf_member_report_facts(Bs, Member) :-

	/*
	these accounts are subcategorized into phase and taxability, so we generate the aspect sets automatically
	*/

	!maplist(!smsf_member_report_concept_to_aspects1(Member),
	[
		'Opening Balance',
		'Transfers In',
		'Pensions Paid',
		'Benefits Paid',
		'Transfers Out',
		'Life Insurance Premiums',
		'Share of Profit/(Loss)',
		'Income Tax',
		'Contribution Tax',
		'Internal Transfers In',
		'Internal Transfers Out'
	],
	Aspects0),
	flatten(Aspects0, Aspects1),

	/*
	these arent, so we specify phase and taxability by hand
	*/

	!append(Aspects1,
	[
		aspects([
			account_role - 'Employer Contributions - Concessional' / Member,
			concept - smsf/member/'Employer Contributions - Concessional',
			phase - 'Restricted Non Preserved',
			taxability - 'Tax Free',
			member - Member
		]),
		aspects([
			account_role - 'Member/Personal Contributions - Concessional' / Member,
			concept - smsf/member/'Member/Personal Contributions - Concessional',
			phase - 'Restricted Non Preserved',
			taxability - 'Tax Free',
			member - Member
		]),
		aspects([
			account_role - 'Member/Personal Contributions - Non Concessional' / Member,
			concept - smsf/member/'Member/Personal Contributions - Non Concessional',
			phase - 'Restricted Non Preserved',
			taxability - 'Tax Free',
			member - Member
		]),
		aspects([
			account_role - 'Other Contributions' / Member,
			concept - smsf/member/'Other Contributions',
			phase - 'Restricted Non Preserved',
			taxability - 'Tax Free',
			member - Member
		])
	],
	Aspects2),
	Phases = ['Preserved', 'Unrestricted Non Preserved', 'Restricted Non Preserved'],
	!maplist(add_fact_by_account_role(Bs), Aspects2),
	!maplist(smsf_member_report_add_total_additions(Member), Phases),
	!maplist(smsf_member_report_add_ob_plus_additions(Member), Phases),
	!maplist(smsf_member_report_add_total_subtractions(Member), Phases),
	!maplist(smsf_member_report_add_total(Member), Phases).

smsf_member_report_add_ob_plus_additions(Member, Phase) :-
	!facts_vec_sum($>smsf_member_facts_by_aspects(Member, Phase, smsf/member/'Opening Balance'), Vec1),
	!facts_vec_sum($>smsf_member_facts_by_aspects(Member, Phase, smsf/member/'total additions'), Vec2),
	vec_sum([Vec1, Vec2], Vec),
	!make_fact(Vec,
		aspects([
			concept - smsf/member/'opening balance + additions',
			phase - Phase,
			member - Member
		]),_).

smsf_member_report_add_total_additions(Member, Phase) :-
	Concepts =
	[
		smsf/member/'Member/Personal Contributions - Concessional',
		smsf/member/'Member/Personal Contributions - Non Concessional',
		smsf/member/'Member/Other Contributions',
		smsf/member/'Govt Co-Contributions',
		smsf/member/'Employer Contributions - Concessional',
		smsf/member/'Proceeds of Insurance Policies',
		smsf/member/'Share of Profit/(Loss)',
		smsf/member/'Internal Transfers In',
		smsf/member/'Transfers In'
	],
	!maplist(smsf_member_facts_by_aspects(Member, Phase), Concepts, Facts0),
	flatten(Facts0, Facts),
	!facts_vec_sum(Facts, Vec),
	!make_fact(Vec,
		aspects([
			concept - smsf/member/'total additions',
			phase - Phase,
			member - Member
		]),_).

smsf_member_report_add_total_subtractions(Member, Phase) :-
	Concepts =
	[
		smsf/member/'Benefits Paid',
		smsf/member/'Pensions Paid',
		smsf/member/'Contribution Tax',
		smsf/member/'Income Tax',
		smsf/member/'Life Insurance Premiums',
		smsf/member/'Internal Transfers Out',
		smsf/member/'Transfers Out'
	],
	!maplist(smsf_member_facts_by_aspects(Member, Phase), Concepts, Facts0),
	flatten(Facts0, Facts),
	!facts_vec_sum(Facts, Vec),
	!make_fact(Vec,
		aspects([
			concept - smsf/member/'total subtractions',
			phase - Phase,
			member - Member
		]),_).

smsf_member_report_add_total(Member, Phase) :-
	!facts_by_aspects(
		aspects([
			account_role - _,
			phase - Phase,
			member - Member
		]), Facts),
	!facts_vec_sum(Facts, Vec),
	!make_fact(Vec,
		aspects([
			concept - smsf/member/'total',
			phase - Phase,
			member - Member
		]),_).

smsf_member_facts_by_aspects(Member, Phase, Concept, Facts) :-
	!facts_by_aspects(
		aspects([
			concept - Concept,
			phase - Phase,
			member - Member
		]), Facts).

/*'opening balance + additions'
'total subtractions'
'total'*/


smsf_member_report_concept_to_aspects1(Member, Concept, Facts) :-
	Facts = [
		aspects([
			account_role - ($>atomic_list_concat([Concept, ' - Preserved/Taxable'])) / Member,
			concept - smsf/member/Concept,
			phase - 'Preserved',
			taxability - 'Taxable',
			member - Member
		]),
		aspects([
			account_role - ($>atomic_list_concat([Concept, ' - Preserved/Tax Free'])) / Member,
			concept - smsf/member/Concept,
			phase - 'Preserved',
			taxability - 'Tax Free',
			member - Member
		]),
		aspects([
			account_role - ($>atomic_list_concat([Concept, ' - Unrestricted Non Preserved/Taxable'])) / Member,
			concept - smsf/member/Concept,
			phase - 'Unrestricted Non Preserved',
			taxability - 'Taxable',
			member - Member
		]),
		aspects([
			account_role - ($>atomic_list_concat([Concept, ' - Unrestricted Non Preserved/Tax Free'])) / Member,
			concept - smsf/member/Concept,
			phase - 'Unrestricted Non Preserved',
			taxability - 'Tax Free',
			member - Member
		]),
		aspects([
			account_role - ($>atomic_list_concat([Concept, ' - Restricted Non Preserved/Taxable'])) / Member,
			concept - smsf/member/Concept,
			phase - 'Restricted Non Preserved',
			taxability - 'Taxable',
			member - Member
		]),
		aspects([
			account_role - ($>atomic_list_concat([Concept, ' - Restricted Non Preserved/Tax Free'])) / Member,
			concept - smsf/member/Concept,
			phase - 'Restricted Non Preserved',
			taxability - 'Tax Free',
			member - Member
		])
	].


