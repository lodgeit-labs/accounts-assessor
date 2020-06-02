

add_smsf_member_details_report_facts(Json_reports, Member) :-
	!smsf_member_details_report_aspectses(Member, Aspectses),
	/* Aspectses now contains one aspects term for each gl account of Member in smsf equity members section. */
	/* for each Aspectses member, get gl balance of account_role and assert a fact with vector. */
	!maplist(add_fact_by_account_role(Json_reports), Aspectses),
	/* assert some derived facts for easier referencing */
	Phases = ['Preserved', 'Unrestricted Non Preserved', 'Restricted Non Preserved'],
	!maplist(smsf_member_report_add_total_additions(Member), Phases),
	!maplist(smsf_member_report_add_ob_plus_additions(Member), Phases),
	!maplist(smsf_member_report_add_total_subtractions(Member), Phases),
	!maplist(smsf_member_report_add_total(Member), Phases).


/*

produce all aspectses to look up in GL and assert

*/

smsf_member_details_report_aspectses(Member, Aspectses) :-
	!maplist(!smsf_member_details_report_aspectses3(Member),
	[
		x(bs/current, 'Opening Balance', []),
		x(bs/delta, 'Transfers In', [effect - addition]),
		x(bs/delta, 'Pensions Paid', [effect - subtraction]),
		x(bs/delta, 'Benefits Paid', [effect - subtraction]),
		x(bs/delta, 'Transfers Out', [effect - subtraction]),
		x(bs/delta, 'Life Insurance Premiums', [effect - subtraction]),
		x(bs/delta, 'Share of Profit/(Loss)', [effect - addition]),
		x(bs/delta, 'Income Tax', [effect - subtraction]),
		x(bs/delta, 'Contribution Tax', [effect - subtraction]),
		x(bs/delta, 'Internal Transfers In', [effect - addition]),
		x(bs/delta, 'Internal Transfers Out', [effect - subtraction])
	],
	Aspectses0),
	smsf_member_details_report_aspectses6(Member, Aspectses1),
	!append($>flatten(Aspectses0), $>flatten(Aspectses1), Aspectses).

smsf_member_details_report_aspectses3(Member, x(Report, Concept, Additional_aspects), Facts) :-
	/*
	these accounts are all subcategorized into phase and taxability in the same way, so we generate the aspect sets automatically
	*/
	'='(Facts, [
		aspects($>append([
			report - Report,
			account_role - ($>atomic_list_concat([Concept, ' - Preserved/Taxable'])) / Member,
			concept - smsf/member/gl/Concept,
			phase - 'Preserved',
			taxability - 'Taxable',
			member - Member
		], Additional_aspects)),
		aspects($>append([
			report - Report,
			account_role - ($>atomic_list_concat([Concept, ' - Preserved/Tax Free'])) / Member,
			concept - smsf/member/gl/Concept,
			phase - 'Preserved',
			taxability - 'Tax Free',
			member - Member
		], Additional_aspects)),
		aspects($>append([
			report - Report,
			account_role - ($>atomic_list_concat([Concept, ' - Unrestricted Non Preserved/Taxable'])) / Member,
			concept - smsf/member/gl/Concept,
			phase - 'Unrestricted Non Preserved',
			taxability - 'Taxable',
			member - Member
		], Additional_aspects)),
		aspects($>append([
			report - Report,
			account_role - ($>atomic_list_concat([Concept, ' - Unrestricted Non Preserved/Tax Free'])) / Member,
			concept - smsf/member/gl/Concept,
			phase - 'Unrestricted Non Preserved',
			taxability - 'Tax Free',
			member - Member
		], Additional_aspects)),
		aspects($>append([
			report - Report,
			account_role - ($>atomic_list_concat([Concept, ' - Restricted Non Preserved/Taxable'])) / Member,
			concept - smsf/member/gl/Concept,
			phase - 'Restricted Non Preserved',
			taxability - 'Taxable',
			member - Member
		], Additional_aspects)),
		aspects($>append([
			report - Report,
			account_role - ($>atomic_list_concat([Concept, ' - Restricted Non Preserved/Tax Free'])) / Member,
			concept - smsf/member/gl/Concept,
			phase - 'Restricted Non Preserved',
			taxability - 'Tax Free',
			member - Member
		], Additional_aspects))
	]).


smsf_member_details_report_aspectses6(Member, Aspectses) :-
	/*
	these arent, so we specify phase and taxability by hand
	*/
	Aspectses = [
		aspects([
			report - bs/delta,
			account_role - 'Employer Contributions - Concessional' / Member,
			concept - smsf/member/gl/'Employer Contributions - Concessional',
			phase - 'Preserved',
			taxability - 'Taxable',
			member - Member,
			effect - addition
		]),
		aspects([
			report - bs/delta,
			account_role - 'Member/Personal Contributions - Concessional' / Member,
			concept - smsf/member/gl/'Member/Personal Contributions - Concessional',
			phase - 'Preserved',
			taxability - 'Taxable',
			member - Member,
			effect - addition
		]),
		aspects([
			report - bs/delta,
			account_role - 'Member/Personal Contributions - Non Concessional' / Member,
			concept - smsf/member/gl/'Member/Personal Contributions - Non Concessional',
			phase - 'Preserved',
			taxability - 'Tax Free',
			member - Member,
			effect - addition
		]),
		aspects([
			report - bs/delta,
			account_role - 'Other Contributions' / Member,
			concept - smsf/member/gl/'Other Contributions',
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
	!facts_by_aspects(
		aspects([
			account_role - _,
			phase - Phase,
			member - Member,
			effect - addition
		]), Facts),
	!facts_vec_sum(Facts, Vec),
	!make_fact(Vec,
		aspects([
			concept - smsf/member/derived/'total additions',
			phase - Phase,
			member - Member
		]),_).

smsf_member_report_add_total_subtractions(Member, Phase) :-
	!facts_by_aspects(
		aspects([
			account_role - _,
			phase - Phase,
			member - Member,
			effect - subtraction
		]), Facts),
	!facts_vec_sum(Facts, Vec),
	!make_fact(Vec,
		aspects([
			concept - smsf/member/derived/'total subtractions',
			phase - Phase,
			member - Member
		]),_).

smsf_member_report_add_ob_plus_additions(Member, Phase) :-
	!facts_vec_sum($>smsf_member_facts_by_aspects(Member, Phase, smsf/member/gl/'Opening Balance'), Vec1),
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



