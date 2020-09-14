
/*

1:
	list all smsf_equity gl accounts, verify that for each one, there is a fact with that account_role
*/
smsf_member_report_check1(Json) :-
	!account_by_role_has_descendants(smsf_equity, Descendants),
	findall(Ch, (member(Ch, Descendants), account_role(Ch, _)), Equity_accounts_with_role),
	maplist(smsf_check1_3(Json), Equity_accounts_with_role).

smsf_check1_3(Json, Ch) :-
	!account_role(Ch, Role),
	(	find_account_role_in_smsf_report_tables(Json, Role)
	->	true
	;	(throw_string([Role, ' not found in smsf member reports']))).


find_account_role_in_smsf_report_tables(Json, Role) :-
	member(Reports, Json),
	Reports = _{overview:_, details:Tbl2},
	member(Row, Tbl2.rows),
	member(Cell, Row),
	Cell = with_metadata(_, Metadata),
	member(aspects(Aspects), Metadata),
	member(account_role - Role, Aspects).

/*

2:
	verify that all smsf/member/gl/ facts have 'effect'
3:
	collect gl balances for all 3 phases, both taxabilities, and a total. Verify report dict entries

*/
