/*

the smsf workflow:
	for report for 2018-2019:

	GL opening balances are posted. this includes:
		!Opening_Balance_-_Preserved/Taxable!<Member>!
			the 2017 opening balance
		!Transfers_In_-_Preserved/Tax-Free!<Member>!
		!Share_of_Profit/(Loss)_-_Preserved/Taxable!<Member>!
		!Income_Tax_-_Preserved/Taxable!<Member>!
			the allocations of 17-18 profits etc

	at the beginning of 18-19(or at end, doesn't matter), we rollover the 17-18 allocations into Opening Balance.
		now Opening Balance is truly the opening balance at 2018.
		now the allocation accounts are zeroed out.

	at the end of 18-19, we allocate profit etc

*/

add_smsf_member_details_report_facts(Json_reports, Member) :-
	!smsf_member_details_report_aspectses(Member, Aspectses),
	/* Aspectses now contains one aspects term for each gl account of Member in smsf equity members section. */
	/* for each Aspectses member, get gl balance of account_role and assert a fact with vector. */
	!maplist(add_fact_by_account_role(Json_reports), Aspectses),
	/* assert some derived facts for easier referencing */
	Phases = ['Preserved', 'Unrestricted_Non_Preserved', 'Restricted_Non_Preserved'],
	!maplist(smsf_member_report_add_total_additions(Member), Phases),
	!maplist(smsf_member_report_add_ob_plus_additions(Member), Phases),
	!maplist(smsf_member_report_add_total_subtractions(Member), Phases),
	!maplist(smsf_member_report_add_total(Member), Phases).

/*

produce all aspectses to later look up in GL and assert

*/

smsf_member_details_report_aspectses(Member, Aspectses) :-
	!maplist(!smsf_member_details_report_aspectses3(Member),
	[
		x(final/bs/current, 'Opening_Balance', []),
		/* effect etc should be something else than an aspect. A tag perhaps. */
		x(final/bs/current, 'Transfers_In', [effect - addition]),
		x(final/bs/current, 'Pensions_Paid', [effect - subtraction]),
		x(final/bs/current, 'Benefits_Paid', [effect - subtraction]),
		x(final/bs/current, 'Transfers_Out', [effect - subtraction]),
		x(final/bs/current, 'Life_Insurance_Premiums', [effect - subtraction]),
		x(final/bs/current, 'Share_of_Profit/(Loss)', [effect - addition]),
		x(final/bs/current, 'Income_Tax', [effect - subtraction]),
		x(final/bs/current, 'Contribution_Tax', [effect - subtraction]),
		x(final/bs/current, 'Internal_Transfers_In', [effect - addition]),
		x(final/bs/current, 'Internal_Transfers_Out', [effect - subtraction])
	],
	Aspectses0),
	smsf_member_details_report_aspectses6(Member, Aspectses1),
	!append($>flatten(Aspectses0), $>flatten(Aspectses1), Aspectses).

smsf_member_details_report_aspectses3(Member, x(Report, Concept, Additional_aspects), Facts) :-
	/*
	these accounts are all subcategorized into phase and taxability in the same way, so we generate the aspect sets automatically
	*/
	'='(
		Facts,
		[
			aspects($>append([
				report - Report,
				account_role - ($>atomic_list_concat([Concept, '_-_Preserved/Taxable'])) / Member,
				concept - smsf/member/gl/Concept,
				phase - 'Preserved',
				taxability - 'Taxable',
				member - Member
			], Additional_aspects)),
			aspects($>append([
				report - Report,
				account_role - ($>atomic_list_concat([Concept, '_-_Preserved/Tax-Free'])) / Member,
				concept - smsf/member/gl/Concept,
				phase - 'Preserved',
				taxability - 'Tax-Free',
				member - Member
			], Additional_aspects)),
			aspects($>append([
				report - Report,
				account_role - ($>atomic_list_concat([Concept, '_-_Unrestricted_Non_Preserved/Taxable'])) / Member,
				concept - smsf/member/gl/Concept,
				phase - 'Unrestricted_Non_Preserved',
				taxability - 'Taxable',
				member - Member
			], Additional_aspects)),
			aspects($>append([
				report - Report,
				account_role - ($>atomic_list_concat([Concept, '_-_Unrestricted_Non_Preserved/Tax-Free'])) / Member,
				concept - smsf/member/gl/Concept,
				phase - 'Unrestricted_Non_Preserved',
				taxability - 'Tax-Free',
				member - Member
			], Additional_aspects)),
			aspects($>append([
				report - Report,
				account_role - ($>atomic_list_concat([Concept, '_-_Restricted_Non_Preserved/Taxable'])) / Member,
				concept - smsf/member/gl/Concept,
				phase - 'Restricted_Non_Preserved',
				taxability - 'Taxable',
				member - Member
			], Additional_aspects)),
			aspects($>append([
				report - Report,
				account_role - ($>atomic_list_concat([Concept, '_-_Restricted_Non_Preserved/Tax-Free'])) / Member,
				concept - smsf/member/gl/Concept,
				phase - 'Restricted_Non_Preserved',
				taxability - 'Tax-Free',
				member - Member
			], Additional_aspects))
		]
	).


smsf_member_details_report_aspectses6(Member, Aspectses) :-
	/*
	these arent, so we specify phase and taxability by hand
	*/
	/*
	todo store these hack facts in rdf, generate documentation automatically
	*/
	Aspectses = [
		aspects([
			report - final/bs/current,
			account_role - 'Employer_Contributions_-_Concessional' / Member,
			concept - smsf/member/gl/'Employer_Contributions_-_Concessional',
			phase - 'Preserved',
			taxability - 'Taxable',
			member - Member,
			effect - addition
		]),
		aspects([
			report - final/bs/current,
			account_role - 'Member/Personal_Contributions_-_Concessional' / Member,
			concept - smsf/member/gl/'Member/Personal_Contributions_-_Concessional',
			phase - 'Preserved',
			taxability - 'Taxable',
			member - Member,
			effect - addition
		]),
		aspects([
			report - final/bs/current,
			account_role - 'Member/Personal_Contributions_-_Non_Concessional' / Member,
			concept - smsf/member/gl/'Member/Personal_Contributions_-_Non_Concessional',
			phase - 'Preserved',
			taxability - 'Tax-Free',
			member - Member,
			effect - addition
		]),
		aspects([
			report - final/bs/current,
			account_role - 'Other_Contributions' / Member,
			concept - smsf/member/gl/'Other_Contributions',
			phase - 'Preserved',
			taxability - 'Taxable',
			member - Member,
			effect - addition
		])
	].




/*
╺┳┓┏━╸┏━┓╻╻ ╻┏━╸╺┳┓   ┏━╸┏━┓┏━╸╺┳╸┏━┓
 ┃┃┣╸ ┣┳┛┃┃┏┛┣╸  ┃┃   ┣╸ ┣━┫┃   ┃ ┗━┓
╺┻┛┗━╸╹┗╸╹┗┛ ┗━╸╺┻┛   ╹  ╹ ╹┗━╸ ╹ ┗━┛
assert derived summation facts
*/

smsf_member_report_add_total_additions(Member, Phase) :-
	!add_summation_fact([
		aspects([
			account_role - _,
			phase - Phase,
			member - Member,
			effect - addition
		])],
		aspects([
			concept - smsf/member/derived/'total additions',
			phase - Phase,
			member - Member
		])).

smsf_member_report_add_total_subtractions(Member, Phase) :-
	!add_summation_fact([
		aspects([
			account_role - _,
			phase - Phase,
			member - Member,
			effect - subtraction
		])],
		aspects([
			concept - smsf/member/derived/'total subtractions',
			phase - Phase,
			member - Member
		])).

smsf_member_report_add_ob_plus_additions(Member, Phase) :-
	!facts_vec_sum($>smsf_member_facts_by_aspects(Member, Phase, smsf/member/gl/'Opening_Balance'), Vec1),
	!facts_vec_sum($>smsf_member_facts_by_aspects(Member, Phase, smsf/member/derived/'total additions'), Vec2),
	vec_sum([Vec1, Vec2], Vec),
	!make_fact(Vec,
		aspects([
			concept - smsf/member/derived/'opening balance + additions',
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
			concept - smsf/member/derived/'total',
			phase - Phase,
			member - Member
	]),_).




/*
╻  ┏━┓┏━┓╻┏ ╻ ╻┏━┓
┃  ┃ ┃┃ ┃┣┻┓┃ ┃┣━┛
┗━╸┗━┛┗━┛╹ ╹┗━┛╹
*/
smsf_member_facts_by_aspects(Member, Phase, Concept, Facts) :-
	!facts_by_aspects(
		aspects([
			concept - Concept,
			phase - Phase,
			member - Member
		]), Facts).




