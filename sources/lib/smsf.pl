/*

resources:

https://www.taxandsuperaustralia.com.au/TSA/Members/SMSF_Toolkit.aspx#Sample
https://sf360.zendesk.com/hc/en-au/articles/360018366011-Create-Entries-Report
https://sf360.zendesk.com/hc/en-au/articles/360017821211-The-Create-Entries-Process

*/

 smsf_members_throw(Members) :-
	doc_list_items($>value($>get_optional_singleton_sheet_data(smsf_ui:members_sheet)), Members),
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
		their value given by opening market values ends up in Historical_Earnings
	use GL_input to clear out Historical_Earnings into member opening balances.

	PL is always computed just for current period. Old transactions stay there but are not taken into account. At end of period, total of PL is copied over to retaine

*/


