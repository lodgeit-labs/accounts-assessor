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
	distribution_txs(Default_currency, Item, Unit, Txs),
	assert_smsf_distribution_facts(Default_currency, Unit, Item).

assert_smsf_distribution_facts(Default_currency, Unit, Item) :-
	optionally_assert_doc_value_as_fact(Item, smsf_distribution_ui:franking_credit, Default_currency,
		aspects([
			concept - smsf/distribution/franking_credit,
			unit - Unit
	])),
	optionally_assert_doc_value_as_fact(Item, smsf_distribution_ui:foreign_credit, Default_currency,
		aspects([
			concept - smsf/distribution/foreign_credit,
			unit - Unit
	])).

 optionally_assert_doc_value_as_fact(Item, Prop, Default_currency, Aspects) :-
	(	read_value_from_doc_string(Item, Prop, Default_currency, Value)
	->	make_fact(Value, Aspects)
	;	true).


distribution_txs(Default_currency, Item, Unit, Txs) :-
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
	(	read_coord_vector_from_doc_string(Item, Prop, Default_currency, kb:credit, VectorA)
	->	(
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

read_coord_vector_from_doc_string(Item, Prop, Default_currency, Side, VectorA) :-
	doc_value(Item, Prop, Amount_string),
	(	vector_from_string(Default_currency, Side, Amount_string, VectorA)
	->	true
	;	throw_string(['error reading "amount" in ', $>!sheet_and_cell_string($>doc(Item, Prop))])).

 read_value_from_doc_string(Item, Prop, Default_currency, Value) :-
	doc_value(Item, Prop, Amount_string),
	(	value_from_string(Default_currency, Amount_string, Value)
	->	true
	;	(
			assert(var(Value)),
			throw_string(['error reading "amount" in ', $>!sheet_and_cell_string($>doc(Item, Prop))])
		)
	).



/*

first class formulas:

	"Accounting Equation"
		assets - liabilities = equity

	smsf:
		'Benefits Accrued as a Result of Operations before Income Tax' = 'P&L' + 'Writeback Of Deferred Tax' + 'Income Tax Expenses'

	there is a choice between dealing with (normal-side) values vs dr/cr coords. A lot of what we need to express are not naturally coords, and dealing with them as coords would be confusing. Otoh, translating gl account coords to normal side values can make things confusing too, as seen above.

	'Benefits Accrued as a Result of Operations before Income Tax' = 'P&L', excluding: 'Writeback Of Deferred Tax', 'Income Tax Expenses'



*/
