:- module(_, []).

:- use_module(library(debug)).
:- use_module(library(xpath)).

:- debug(d).

/*
this is just a first shot at parsing the UBL invoice schema
*/
process_invoices_payable(Request_Dom) :-
	%gtrace,
	%Cac='urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
	Inv2 = 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2'
	,findall(Dom, xpath(Request_Dom, //reports/balanceSheetRequest/invoicesPayable/(ns(_,Inv2):'Invoice'), Dom), Doms)
	%,debug(d, '~k', [Doms])
	,process_invoices_payable2(Doms)
	.
process_invoices_payable2([]).
process_invoices_payable2([Dom|Doms]) :-
	debug(d, 'XXXXXXXX', [])
	,Cac='urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'
	,findall(Line,xpath(Dom, ns(_,Cac):'InvoiceLine',Line),Lines)
	%,print_term(Dom2, [output(user_error)]) 
	,maplist(process_line, Lines)
	,process_invoices_payable2(Doms)
	.
process_line(Line) :-
	cac(Cac),cbc(Cbc)
	,xpath(Line, ns(_,Cbc):'InvoicedQuantity',_Q)
	,xpath(Line, ns(_,Cbc):'LineExtensionAmount',_A)
	,xpath(Line, ns(_,Cac):'Item',_I)
	. 

cac('urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2').
cbc('urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2').
