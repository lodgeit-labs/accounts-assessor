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
 	(	doc_value(Rd, smsf:distribution, D),
 	->	extract_smsf_distribution2(D, Txs)
 	;	true).

extract_smsf_distribution2(D, Txs) :-
	doc_list_members(D, Items),
	maplist(extract_smsf_distribution3, Items, Txs).

extract_smsf_distribution3(Item, []) :-
	doc_value(Item, distribution_ui:name, "Dr/Cr").

extract_smsf_distribution3(Item, Txs) :-
	doc_value(Item, distribution_ui:name, Unit_name_str),
	atom_string(Unit_name, Unit_name_str),
	traded_units(S_Transactions, Traded_Units),
	(	member(Unit_name, Traded_Units)
	->	true
	;	throw_string('smsf distribution sheet: unknown unit: ', Unit_name])),
	



