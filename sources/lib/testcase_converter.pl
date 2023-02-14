% git show 5e334b610c7af43382235148e0bae202220ba9fd



 process_request_ledger_xml(File_Path, Dom) :-
	assertion(Dom = [element(_,_,_)]),
	inner_xml(Dom, //reports/balanceSheetRequest, _),
	!cf(validate_xml2(File_Path, 'bases/Reports.xsd')),


	Data = (Dom, Start_Date, End_Date, Output_Dimensional_Facts, Cost_Or_Market, Report_Currency),



	result_data(Result_Data),
	doc_add(Result_Data, ic_ui:report_details, Report_Details),




	!cf(extract_request_details(Dom)),
	!cf(extract_start_and_end_date(Dom, Start_Date, End_Date)),
	!cf('extract "output_dimensional_facts"'(Dom, Output_Dimensional_Facts)),
	!cf('extract "cost_or_market"'(Dom, Cost_Or_Market)),

	!cf(extract_report_currency_into_rdf(Dom, Report_Currency)),

	!cf('extract bank accounts (XML)'(Dom)),
	!cf(extract_s_transactions(Dom, S_Transactions1)),
	!cf(extract_livestock_data_from_ledger_request(Dom)),
	!cf(extract_exchange_rates(Cost_Or_Market, Dom, S_Transactions, Start_Date, End_Date, Report_Currency, Exchange_Rates)),
	;	inner_xml_throw(Dom, //reports/balanceSheetRequest/reportCurrency/unitType, Report_Currency)).









 extract_report_currency_into_rdf(Dom, Report_Details, Report_Currency) :-
	inner_xml_throw(Dom, //reports/balanceSheetRequest/reportCurrency/unitType, [Report_Currency]),
	gtrace,
	atom_string(Report_Currency, Report_Currency_String),
	doc_value_add(Report_Details, ic:currency, Report_Currency_String).











