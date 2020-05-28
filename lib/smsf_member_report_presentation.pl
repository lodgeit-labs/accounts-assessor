smsf_member_report_presentation(Cols2) :-

	Opening_balance_label = text('Opening Balance at ~w'.format($>request_has_property(l:end_date))),

	Phase_dimension = dimension(phase, ['Preserved','Restricted Non Preserved', 'Unrestricted Non Preserved', 'Total']),

	Tbl1 = [
		text('Opening_balance_label'                                ),concept('Opening Balance'),
		text('Add: Increases to Member\'s Account During the Period'),text(''),
		text('Concessional Contributions'                           ),concept('Member/Personal Contributions - Concessional'),
		text('Non-Concessional Contributions'                       ),concept('Member/Personal Contributions - Non Concessional'),
		text('Other Contributions'                                  ),concept('Member/Other Contributions'),
		text('Govt Co-Contributions'                                ),concept('Govt Co-Contributions'),
		text('Employer Contributions - No TFN'                      ),concept('Employer Contributions - Concessional'),
		text('Proceeds of Insurance Policies'                       ),concept('Proceeds of Insurance Policies'),
		text('Share of Net Income/(Loss) for period'                ),concept('Share of Profit/(Loss)'),
		text('Transfers in and transfers from reserves'             ),concept('Internal Transfers In'),
		text(''                                                     ),hr,
		text(''                                                     ),concept('total additions'),
		text(''                                                     ),hr,
		text(''                                                     ),concept('opening balance + additions'),
		text(''                                                     ),text(''),
		text('Less: Decreases to Member's Account During the Period'),text(''),
		text('Benefits Paid'                                        ),concept('Benefits Paid'),
		text('Pensions Paid'                                        ),concept('Pensions Paid'),
		text('Contributions Tax'                                    ),concept('Contribution Tax'),
		text('Income Tax'                                           ),concept('Income Tax'),
		text('No TFN Excess Contributions Tax'                      ),concept('No TFN Excess Contributions Tax'),
		text('Division 293 Tax'                                     ),concept('Division 293 Tax'),
		text('Excess Contributions Tax'                             ),concept('Excess Contributions Tax'),
		text('Refund Excess Contributions'                          ),concept('Refund Excess Contributions'),
		text('Insurance Policy Premiums Paid'                       ),concept('Life Insurance Premiums'),
		text('Management Fees'                                      ),concept('Management Fees'),
		text('Share of fund expenses'                               ),concept('Share of fund expenses'),
		text('Transfers out and transfers to reserves'              ),concept('Internal Transfers Out'),
		text(''                                                     ),hr,
		text(''                                                     ),concept('total subtractions'),
		text(''                                                     ),hr,
		text(''                                                     ),concept('total'),
	],
	maplist(nth0(0), Tbl1, Labels),
	maplist(nth0(1), Tbl1, Col1),
	maplist(prepend_concept_prefix(Col1,smsf/member,Col1_2),
	maplist(columnize_by_dimension(Phase_dimension), Col1_2, Cols1),
	maplist([A,B,C] append([A], B, C), Col1_2, Cols1, Cols2).

prepend_concept_prefix(concept(C), Prefix, concept(Prefix/C)) :- !.
prepend_concept_prefix(X, _, X) :- !.

columnize_by_dimension(dimension(_,[]), _, []).
columnize_by_dimension(dimension(Dim_name, [Point|Points_rest]), Cell, [Fact|Facts_rest]) :-
	Cell = concept(X),
	Fact = fact([
		concept - X,
		Dim_name - Point
	],
	columnize_by_dimension(dimension(Dim_name, Points_rest), Cell, Facts_rest).

add_aspect(Aspect, In, Out) :-
	maplist(add_aspect2(Aspect), In, Out).
add_aspect2(Aspect, In, Out) :-
	maplist(add_aspect3(Aspect), In, Out).
add_aspect3(Aspect, X, X) :-
	X = text(_) ; X = hr.
add_aspect3(Aspect, fact(Aspects), fact(Aspects2)) :-
	append(Aspects, [Aspect], Aspects2).
