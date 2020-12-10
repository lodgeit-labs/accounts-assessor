 smsf_member_report_presentation(Presentation) :-

	format(string(Opening_balance_label), 'Opening Balance at ~w', [$>format_date($>request_has_property(l:start_date))]),
	format(string(Closing_balance_label), 'Closing Balance at ~w', [$>format_date($>request_has_property(l:end_date))]),

	Phase_dimension = dimension(phase, ['Preserved','Restricted Non Preserved', 'Unrestricted Non Preserved']),

	Tbl1 = [
		[text(Opening_balance_label),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Opening_Balance'])],

		[text('Add: Increases to Member\'s Account During the Period'),
			text('')],

		[text('Concessional Contributions'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Member/Personal_Contributions_-_Concessional'])],

		[text('Non-Concessional Contributions'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Member/Personal_Contributions_-_Non_Concessional'])],

		[text('Other_Contributions'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Other_Contributions'])],

		/* missing */
		/*[text('Govt Co-Contributions'),                                  concept('Govt Co-Contributions')],
		[text('Employer_Contributions - No TFN'),                        concept('Employer_Contributions_-_Concessional')],*/
		/* missing */
		/*[text('Proceeds of Insurance Policies'),                         concept('Proceeds of Insurance Policies')],*/
		[text('Share of Net Income/(Loss) for period'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Share_of_Profit/(Loss)'])],

		[text('Internal_Transfers_In'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Internal_Transfers_In'])],

		[text('Transfers_In'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Transfers_In'])],

		[text(''),                                                       text('')],

		[text('total additions'),
			aspects([
				concept - smsf/member/derived/'total additions'])],

		[text(''),                                                       text('')],

		[text('opening balance + additions'),
			aspects([
				concept - smsf/member/derived/'opening balance + additions'])],

		[text(''),                                                       text('')],
		[text('Less: Decreases to Member\'s Account During the Period'), text('')],

		[text('Benefits_Paid'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Benefits_Paid'])],

		[text('Pensions_Paid'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Pensions_Paid'])],

		[text('Contribution_Tax'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Contribution_Tax'])],

		[text('Income_Tax'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Income_Tax'])],
		/*
		[text('No TFN Excess Contributions Tax'),                        concept('No TFN Excess Contributions Tax')],
		[text('Division 293 Tax'),                                       concept('Division 293 Tax')],
		[text('Excess Contributions Tax'),                               concept('Excess Contributions Tax')],
		[text('Refund Excess Contributions'),                            concept('Refund Excess Contributions')],
		*/
		[text('Insurance Policy Premiums Paid'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Life_Insurance_Premiums'])],
		/*
		[text('Management Fees'),                                        concept('Management Fees')],
		[text('Share of fund expenses'),                                 concept('Share of fund expenses')],
		*/
		[text('Internal_Transfers_Out'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Internal_Transfers_Out'])],

		[text('Transfers_Out'),
			aspects([
				report - final/bs/current,
				concept - smsf/member/gl/'Transfers_Out'])],

		[text(''),                                                       text('')],

		[text('total subtractions'),
			aspects([
				concept - smsf/member/derived/'total subtractions'])],

		[text(''),                                                       text('')],

		[text(Closing_balance_label),
			aspects([
				concept - smsf/member/derived/'total'])]
	],
	!maplist(nth0(0), Tbl1, Labels),
	!maplist(nth0(1), Tbl1, Aspects1),
	!maplist(!columnize_by_dimension(Phase_dimension), Aspects1, Phase_cols),
	!maplist(smsf_member_report_presentation2, Labels, Phase_cols, Aspects1, Presentation).

smsf_member_report_presentation2(Label, Phase_cols, Total, Row) :-
	append([Label], Phase_cols, X),
	append(X, [Total], Row).

columnize_by_dimension(dimension(_,[]), _, []).

columnize_by_dimension(dimension(Dim_name, [Point|Points_rest]), Cell, [Fact|Facts_rest]) :-
	Cell = aspects(Aspects0),
	append(Aspects0,[Dim_name - Point],Aspects1),
	Fact = aspects(Aspects1),
	!columnize_by_dimension(dimension(Dim_name, Points_rest), Cell, Facts_rest).

columnize_by_dimension(dimension(Dim_name, [_|Points_rest]), Cell, [Cell|Facts_rest]) :-
	Cell \= aspects(_),
	!columnize_by_dimension(dimension(Dim_name, Points_rest), Cell, Facts_rest).
