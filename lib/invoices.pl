:- module(_, []).

:- use_module(library(debug)).
:- use_module(library(xpath)).

:- debug(d).


process_invoices_payable(Request_Dom) :-
	%gtrace,
	%Cac='urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
	Inv2 = 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2'
	%,findall(Dom, xpath(Request_Dom, //reports/balanceSheetRequest/invoicesPayable/(ns('',Inv2):'Invoice'), Dom), Doms)
	,findall(Dom, xpath(Request_Dom, //reports/balanceSheetRequest/invoicesPayable/(ns('',Inv2):'Invoice'), Dom), Doms)
	,debug(d, '~k', [Doms])
	%,process_invoices_payable2(Doms)
	.




/*	process_invoices_payable2(Doms).


process_invoices_payable2([Dom|_Doms]) :-
	debug(d, 'XXXXXXXX', []),
	Cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
	xpath(Dom, (ns('',Cac):'InvoiceLine'), _Dom2),
	process_invoices_payable2(_Doms)
*/
