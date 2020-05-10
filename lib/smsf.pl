/*
resources:

https://www.taxandsuperaustralia.com.au/TSA/Members/SMSF_Toolkit.aspx#Sample
https://sf360.zendesk.com/hc/en-au/articles/360018366011-Create-Entries-Report
https://sf360.zendesk.com/hc/en-au/articles/360017821211-The-Create-Entries-Process

*/

smsf_members_throw(Members) :-
	request_data(D),
	doc_value(D, smsf:members, List),
	doc_list_items(List, Members)
	smsf:member_name

		(	Members = []
	->	throw_string('no SMSF members found')
	;	true).




/*
action verbs in general:
	Invest_In
	Dispose_Off
		magic: affect counteraccount's Unit subaccount




"trading account" parameter of action verb:
	magic: affect "trading account"'s Unit subaccount



*/
/*

phase 1 - setting up opening balances
	use quasi bank sheet to populate investments.
		action verb: Invest_In
		price: 0
		their value given by opening market values ends up in HistoricalEarnings
	use GL_input to clear our HistoricalEarnings into member opening balances.


*/
