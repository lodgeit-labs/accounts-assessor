 /* this was never tested i think.. */
 
 /* now, this is a good (example of a) reason why maintain the cumbersome frontend -> proxy -> worker -> prolog -> python path.
Prolog is the only codebase where we implement the RDF UI logic, (and where we'd probably continue its development.) */


 process_request_loan_rdf :-
	ct(
		"is this a Div7A Calculator query?",
		?get_optional_singleton_sheet_data(div7a_ui:sheet, Loan)
	),

	!doc(Loan, div7a:income_year_of_loan_creation, CreationIncomeYearNumber),
	absolute_day(date(CreationIncomeYearNumber, 7, 1), NCreationIncomeYear),

    !doc(Loan, div7a:full_term_of_loan_in_years, Term),

	/* exactly one of PrincipalAmount or OpeningBalance must be provided */
	/* or we can loosen this requirement, and ignore principal if both are provided */
	(	doc(Loan, div7a:principal_amount_of_loan, Amount)
	->	(	doc(Loan, div7a:opening_balance, OB)
		->	throw_string('both principal amount and opening balance provided')
		;	OB = false)
	;	(	doc(Loan, div7a:opening_balance, OB)
		->	Amount = false
		;	throw_string('no principal amount and no opening balance provided'))),

	absolute_days($>!doc(Loan, div7a:lodgement_day_of_private_company), NLodgementDate),

    !doc(Loan, div7a:income_year_of_computation, ComputationYearNumber),
    calculate_computation_year2(ComputationYearNumber, CreationIncomeYearNumber, NComputationYearIdx),
    maplist(convert_loan_rdf_repayments, $>!doc_list_items($>!doc(Loan, div7a:repayments)), Repayments),

	loan_agr_summary_python0(loan_agreement(
		% loan_agr_contract_number:
		0,
		% loan_agr_principal_amount:
		Amount,
		% loan_agr_lodgement_day:
		NLodgementDate,
		% loan_agr_begin_day:
		NCreationIncomeYear,
		% loan_agr_term (length in years):
		Term,
		% loan_agr_computation_year
		NComputationYearIdx,

		OB,
		% loan_agr_repayments (list):
		Repayments),
		% output:
		Summary),

	div7a_rdf_result(ComputationYearNumber, Summary).



 div7a_rdf_result(ComputationYearNumber, Summary) :-

    Summary = loan_summary(_Number, OpeningBalance, InterestRate, MinYearlyRepayment, TotalRepayment,RepaymentShortfall, TotalInterest, TotalPrincipal, ClosingBalance),

	Row = _{
		income_year: ComputationYearNumber,
		opening_balance: OpeningBalance,
		interest_rate: InterestRate,
		min_yearly_repayment: MinYearlyRepayment,
		total_repayment: TotalRepayment,
		repayment_shortfall: RepaymentShortfall,
		total_interest: TotalInterest,
		total_principal: TotalPrincipal,
		closing_balance: ClosingBalance
	},

	Cols = [
		column{id:income_year, title:"income year", options:_{}},
		column{id:opening_balance, title:"opening balance", options:_{}},
		column{id:interest_rate, title:"interest rate", options:_{}},
		column{id:min_yearly_repayment, title:"min yearly repayment", options:_{}},
		column{id:total_repayment, title:"total repayment", options:_{}},
		column{id:repayment_shortfall, title:"repayment shortfall", options:_{}},
		column{id:total_interest, title:"total interest", options:_{}},
		column{id:total_principal, title:"total principal", options:_{}},
		column{id:closing_balance, title:"closing balance", options:_{}}
	],

	Table_Json = _{title_short: "Div7A", title: "Division 7A", rows: [Row], columns: Cols},
	!table_html([], Table_Json, Table_Html),
   	!page_with_table_html('Div7A', Table_Html, Html),
   	!add_report_page(_Report_Uri, 0, 'Div7A', Html, loc(file_name,'summary.html'), 'summary.html').
	%!add_result_sheets_report($>doc_default_graph)... this will require an on-the-fly conversion from table json to rdf templates + data.



 convert_loan_rdf_repayments(I, loan_repayment(Days,  Value)) :-
 	absolute_days($>!doc_value(I, div7a_repayment:date), Days),
 	$>!doc_value(I, div7a_repayment:value, Value).


