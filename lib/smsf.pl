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


smsf_member_reports :-
	!smsf_members_throw(Members),
	maplist(!smsf_member_report, Members).

 smsf_member_report(Member_uri) :-
	!doc_value(Member_uri, smsf:member_name, Member_Name_str),
	atom_string(Member, Member_Name_str),
	smsf_member_report_presentation(Pres),
	add_aspect(member - Member, Pres, Pres3),
	add_smsf_member_report_facts(Member,
	evaluate_fact_table(Pres3, Tbl),
	Header = ['Your Detailed Account','Preserved','Restricted Non Preserved', 'Unrestricted Non Preserved', 'Total'],


add_smsf_member_report_facts(Member) :-

	Account_roles_and_facts =
	[
		x(
			'Opening Balance - Preserved/Taxable' / Member,
			[
				concept - smsf/member/'Opening Balance',
				phase - 'Preserved',
				taxability - 'Taxable',
				member - Member
			]
		),
	...
	],
	maplist(add_fact_by_account_role(Bs), Account_roles_and_facts),
	smsf_member_add_total_additions(Member, Bs)


smsf_member_add_total_additions(Member) :-
	Roles =
		['Member/Personal Contributions - Concessional'/Member,
		'Member/Personal Contributions - Non Concessional'/Member,
		'Member/Other Contributions'/Member,
		'Govt Co-Contributions'/Member,
		'Employer Contributions - Concessional'/Member,
		'Proceeds of Insurance Policies'/Member,
		'Share of Profit/(Loss)'/Member,
		'Internal Transfers In/Member'/Member],
	add_sum_report_entry(Bs, Roles,
	[
		concept - smsf/member/'total additions',

	]).

add_sum_report_entry(Bs, Roles, New_fact_aspects) :-
	maplist(report_entry_value_by_role(Bs), Roles, Vecs),
	vec_sum(Vecs, Sum),
	make_fact(Vec, New_fact_aspects, _).

report_entry_vec_by_role(Bs, Role, Vec) :-
	!abrlt(Role, Account),
	!accounts_report_entry_by_account_id(Bs, Account, Entry),
	!report_entry_total_vec(Entry, Vec).



concept('total additions'),
concept('opening balance + additions'),
concept('total subtractions'),
concept('total'),




add_smsf_member_report_entry(Bs, x(Role, Aspects)) :-
	report_entry_by_account_role(Bs, Role, Bs_entry)

