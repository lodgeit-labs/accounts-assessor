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




/*
xxx(Role) :-
	abrlt(Role)
	make_report_entry(Name, Children, Uri),
rows_by_aspect(concept
columns(['Your Detailed Account', 'Preserved', 'Restricted Non Preserved', 'Unrestricted Non Preserved', 'Total']),
*/


smsf_member_reports(Bs) :-
	!smsf_members_throw(Members),
	!maplist(!smsf_member_report(Bs), Members).

 smsf_member_report(Bs, Member_uri) :-
	!doc_value(Member_uri, smsf:member_name, Member_Name_str),
	!atom_string(Member, Member_Name_str),
	!smsf_member_report_presentation(Pres),
	!add_aspect(member - Member, Pres, Pres3),
	!add_smsf_member_report_facts(Bs, Member),
	!evaluate_fact_table(Pres3, Tbl),
	Header = ['Your Detailed Account','Preserved','Restricted Non Preserved', 'Unrestricted Non Preserved', 'Total'],
	writeq(Header, Tbl),
	gtrace.



add_smsf_member_report_facts(Bs, Member) :-

	!maplist(smsf_member_report_fact_to_role_mapping1(Member),
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
	Account_roles_and_facts0),
	!append(Account_roles_and_facts0,
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
	Account_roles_and_facts),
	!maplist(add_fact_by_account_role(Bs), Account_roles_and_facts),
	!maplist(smsf_member_add_total_additions(Member), ['Preserved', 'Unrestricted Non Preserved', 'Restricted Non Preserved']).

smsf_member_add_total_additions(Member, Phase) :-
	Concepts =
	[
		smsf/member/'Member/Personal Contributions - Concessional',
		smsf/member/'Member/Personal Contributions - Non Concessional',
		smsf/member/'Member/Other Contributions',
		smsf/member/'Govt Co-Contributions',
		smsf/member/'Employer Contributions - Concessional',
		smsf/member/'Proceeds of Insurance Policies',
		smsf/member/'Share of Profit/(Loss)',
		smsf/member/'Internal Transfers In/Member'
	],
	!maplist(smsf_member_add_total_additions2(Member, Phase), Concepts, Facts),
	!facts_vec_sum(Facts, Vec),
	!make_fact(Vec,
		aspects([
			concept - smsf/member/'total additions',
			phase - Phase,
			member - Member
		]),_).

smsf_member_add_total_additions2(Member, Phase, Concept, Facts) :-
	!facts_by_aspects(
		aspects([
			concept - Concept,
			phase - Phase,
			member - Member
		]), Facts).

/*'opening balance + additions'
'total subtractions'
'total'*/


smsf_member_report_fact_to_role_mapping1(_, [], []).

smsf_member_report_fact_to_role_mapping1(Member, [Concept|Concepts], Facts) :-
	Facts = [
	aspects([
		account_role - ($>atomic_list_concat([Concept, ' - Preserved/Taxable'])) / Member,
		concept - smsf/member/Concept,
		phase - 'Preserved',
		taxability - 'Taxable',
		member - Member
	])/*,
	[
		account_role - $>atomic_list_concat(Concept, ' - Preserved/Tax Free') / Member,
		concept - smsf/member/Concept,
		phase - 'Preserved',
		taxability - 'Tax Free',
		member - Member
	],
	[
		account_role - $>atomic_list_concat(Concept, ' - Unrestricted Non Preserved/Taxable') / Member,
		concept - smsf/member/Concept,
		phase - 'Unrestricted Non Preserved',
		taxability - 'Taxable',
		member - Member
	],
	[
		account_role - $>atomic_list_concat(Concept, ' - Unrestricted Non Preserved/Tax Free') / Member,
		concept - smsf/member/Concept,
		phase - 'Unrestricted Non Preserved',
		taxability - 'Tax Free',
		member - Member
	],
	[
		account_role - $>atomic_list_concat(Concept, ' - Restricted Non Preserved/Taxable') / Member,
		concept - smsf/member/Concept,
		phase - 'Restricted Non Preserved',
		taxability - 'Taxable',
		member - Member
	],
	[
		account_role - $>atomic_list_concat(Concept, ' - Restricted Non Preserved/Tax Free') / Member,
		concept - smsf/member/Concept,
		phase - 'Restricted Non Preserved',
		taxability - 'Tax Free',
		member - Member
	]*/
	| Facts_tail],
	!smsf_member_report_fact_to_role_mapping1(Member, Concepts, Facts_tail).

