

:- dynamic result/1.

do(Pred) :-
	call(Pred, Result),
	assertz(result(Result)).

yield_results(R) :-
	result(R).

find_all_results(Results) :-
	findall(R, yield_results(R), Results).



/*
diff --git a/lib/ledger/process_xml_ledger_request.pl b/lib/ledger/process_xml_ledger_request.pl
index 8a52d1d..3ef161f 100644
--- a/lib/ledger/process_xml_ledger_request.pl
+++ b/lib/ledger/process_xml_ledger_request.pl
@@ -166,7 +166,6 @@ output_results(Static_Data0, Outstanding, Processed_Until, Json_Request_Results)
 	Static_Data.exchange_rates = Exchange_Rates, 
 	Static_Data.accounts = Accounts, 
 	Static_Data.transactions_by_account = Transactions_By_Account, 
-	
 	Static_Data.report_currency = Report_Currency, 
 		
 	writeln("<!-- Build contexts -->"),	
@@ -209,12 +208,12 @@ output_results(Static_Data0, Outstanding, Processed_Until, Json_Request_Results)
 	format_report_entries(xbrl, Accounts, 0, Report_Currency, Instant_Context_Id_Base,  Trial_Balance2, Units2, Units3, [], Tb_Lines),
 
 	investment_reports(Static_Data, Outstanding, Investment_Report_Info),
-	ledger_html_reports:bs_page(Static_Data, Balance_Sheet2, Bs_Report_Page_Info),
-	ledger_html_reports:pl_page(Static_Data, ProfitAndLoss2, '', Pl_Report_Page_Info),
-	ledger_html_reports:pl_page(Static_Data_Historical, ProfitAndLoss2_Historical, '_historical', Pl_Html_Historical_Info),
+	do(ledger_html_reports:bs_page(Static_Data, Balance_Sheet2)),
+	do(ledger_html_reports:pl_page(Static_Data, ProfitAndLoss2, ''),
+	do(ledger_html_reports:pl_page(Static_Data_Historical, ProfitAndLoss2_Historical, '_historical')),
 
-	make_gl_viewer_report(Gl_Viewer_Page_Info),
-	make_gl_report(Static_Data0.gl, '', Gl_Report_File_Info),
+	do(make_gl_viewer_report),
+	do(make_gl_report(Static_Data0.gl, ''),
 	
 	Reports = _{
 		pl: _{
@@ -276,9 +275,7 @@ output_results(Static_Data0, Outstanding, Processed_Until, Json_Request_Results)
 		reports: Reports2
 	}.
 
-/* todo this should be done in output_results */
-make_gl_viewer_report(Info) :-
-	%gtrace,
+make_gl_viewer_report(result{clickable: Info}) :-
 	Viewer_Dir = 'general_ledger_viewer',
 	absolute_file_name(my_static(Viewer_Dir), Viewer_Dir_Absolute, [file_type(directory)]),
 	files:report_file_path(Viewer_Dir, Url, Tmp_Viewer_Dir_Absolute),
@@ -287,10 +284,10 @@ make_gl_viewer_report(Info) :-
 	atomic_list_concat([Url, '/'], Url_With_Slash),
 	report_page:report_entry('GL viewer', Url_With_Slash, Info).
 	
-make_gl_report(Dict, Suffix, Report_File_Info) :-
+make_gl_report(Dict, Suffix, result{clickable_technical: Info}) :-
 	dict_json_text(Dict, Json_Text),
 	atomic_list_concat(['general_ledger', Suffix, '.json'], Fn),
-	report_page:report_item(Fn, Json_Text, Report_File_Info).
+	report_page:report_item(Fn, Json_Text, Info).
 
 print_dimensional_facts(Static_Data, Instant_Context_Id_Base, Duration_Context_Id_Base, Entity_Identifier, Results0, Results3) :-
 	print_banks(Static_Data, Instant_Context_Id_Base, Entity_Identifier, Results0, Results1),

*/
