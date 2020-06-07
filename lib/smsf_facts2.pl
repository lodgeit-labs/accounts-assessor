

add_smsf_member_details_report_facts(Json_reports, Member) :-







/*

produce all aspectses to later look up in GL and assert

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

