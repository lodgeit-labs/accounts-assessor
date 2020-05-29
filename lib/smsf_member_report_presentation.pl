smsf_member_report_presentation(Presentation) :-

	format(string(Opening_balance_label), 'Opening Balance at ~w', [$>format_date($>request_has_property(l:end_date))]),

	Phase_dimension = dimension(phase, ['Preserved','Restricted Non Preserved', 'Unrestricted Non Preserved']),

	Tbl1 = [
		[text(Opening_balance_label),                                    concept('Opening Balance')],
		[text('Add: Increases to Member\'s Account During the Period'),  text('')],
		[text('Concessional Contributions'),                             concept('Member/Personal Contributions - Concessional')],
		[text('Non-Concessional Contributions'),                         concept('Member/Personal Contributions - Non Concessional')],
		[text('Other Contributions'),                                    concept('Other Contributions')],
		/* missing */
		[text('Govt Co-Contributions'),                                  concept('Govt Co-Contributions')],
		[text('Employer Contributions - No TFN'),                        concept('Employer Contributions - Concessional')],
		/* missing */
		[text('Proceeds of Insurance Policies'),                         concept('Proceeds of Insurance Policies')],
		[text('Share of Net Income/(Loss) for period'),                  concept('Share of Profit/(Loss)')],
		[text('Internal Transfers In'),                                  concept('Internal Transfers In')],
		[text('Transfers In'),                                           concept('Transfers In')],
		[text(''),                                                       text('')],
		[text('total additions'),                                        concept('total additions')],
		[text(''),                                                       text('')],
		[text('opening balance + additions'),                            concept('opening balance + additions')],
		[text(''),                                                       text('')],
		[text('Less: Decreases to Member\'s Account During the Period'), text('')],
		[text('Benefits Paid'),                                          concept('Benefits Paid')],
		[text('Pensions Paid'),                                          concept('Pensions Paid')],
		[text('Contribution Tax'),                                       concept('Contribution Tax')],
		[text('Income Tax'),                                             concept('Income Tax')],
		/*
		[text('No TFN Excess Contributions Tax'),                        concept('No TFN Excess Contributions Tax')],
		[text('Division 293 Tax'),                                       concept('Division 293 Tax')],
		[text('Excess Contributions Tax'),                               concept('Excess Contributions Tax')],
		[text('Refund Excess Contributions'),                            concept('Refund Excess Contributions')],
		*/
		[text('Insurance Policy Premiums Paid'),                         concept('Life Insurance Premiums')],
		/*
		[text('Management Fees'),                                        concept('Management Fees')],
		[text('Share of fund expenses'),                                 concept('Share of fund expenses')],
		*/
		[text('Internal Transfers Out'),                                 concept('Internal Transfers Out')],
		[text('Transfers Out'),                                          concept('Transfers Out')],
		[text(''),                                                       text('')],
		[text('total subtractions'),                                     concept('total subtractions')],
		[text(''),                                                       text('')],
		[text('total'),                                                  concept('total')]
	],
	!maplist(nth0(0), Tbl1, Labels),
	!maplist(nth0(1), Tbl1, Col1),
	!maplist(!aspects_from_concept(smsf/member), Col1, Aspects1),
	!maplist(!columnize_by_dimension(Phase_dimension), Aspects1, Phase_cols),
	!maplist(smsf_member_report_presentation2, Labels, Phase_cols, Aspects1, Presentation).

smsf_member_report_presentation2(Label, Phase_cols, Total, Row) :-
	append([Label], Phase_cols, X),
	append(X, [Total], Row).

aspects_from_concept(Prefix, concept(C), aspects([concept-Prefix/C])) :- !.
aspects_from_concept(_, X, X) :- !.


columnize_by_dimension(dimension(_,[]), _, []).

columnize_by_dimension(dimension(Dim_name, [Point|Points_rest]), Cell, [Fact|Facts_rest]) :-
	Cell = aspects([concept-X]),
	Fact = aspects([
		concept - X,
		Dim_name - Point
	]),
	!columnize_by_dimension(dimension(Dim_name, Points_rest), Cell, Facts_rest).

columnize_by_dimension(dimension(Dim_name, [_|Points_rest]), Cell, [Cell|Facts_rest]) :-
	(Cell = text(_);Cell = hr([])),
	!columnize_by_dimension(dimension(Dim_name, Points_rest), Cell, Facts_rest).
