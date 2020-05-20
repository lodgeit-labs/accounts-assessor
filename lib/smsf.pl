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
 	(	doc_value(Rd, smsf:distribution, D)
 	->	extract_smsf_distribution2(D, Txs)
 	;	true).

extract_smsf_distribution2(D, Txs) :-
	doc_list_items(D, Items),
	maplist(extract_smsf_distribution3, Items, Txs).

extract_smsf_distribution3(Item, []) :-
	doc_value(Item, distribution_ui:name, "Dr/Cr").

extract_smsf_distribution3(_Item, _Txs) :- !. /*
	doc_value(Item, distribution_ui:name, Unit_name_str),
	atom_string(Unit, Unit_name_str),
	traded_units(S_Transactions, Traded_Units),
	(	member(Unit, Traded_Units)
	->	true
	;	throw_string(['smsf distribution sheet: unknown unit: ', Unit])),

	doc(Rd, l:end_date, End_Date),


	maplist(smsf_distribution_tx(End_Date),
		dist{
			prop: distribution_ui:accrual,
			a:'Distribution Receivable'/Unit,
			dir:crdr,
			b:'Distribution Received'/Unit,
			desc:"Distributions Accrual entry as per Annual tax statements"},
		dist{
			prop: distribution_ui:franking_credit,
			a:name('Foreign And Other Tax Credits'),
			dir:crdr,
			b:'Distribution Received'/Unit,
			desc:"Tax offset entry against distribution"},
		dist{
			prop: distribution_ui:foreign_credit,
			a:name('Imputed Credits'),
			dir:crdr,
			b:'Distribution Received'/Unit,
			desc:"Tax offset entry against distribution"},
		dist{
			prop: distribution_ui:amit_decrease,
			a:'Investments'/Unit,??
			dir:drcr,
			b:'Distribution Received'/Unit,
			desc:"Recognise the amount of the distribution received & AMIT"},




smsf_distribution_tx(End_Date, Prop) :-
	doc_value(Item, Prop, Value),
	parse_cash,
*/
