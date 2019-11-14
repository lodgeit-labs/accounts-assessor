module(_, []).

:- use_module(library(xpath)).


process_invoices_payable :-
	findall(Dom, xpath(Dom, //reports/balanceSheetRequest/invoicesPayable/Invoice, Dom), Doms),
	writeq(doms).
