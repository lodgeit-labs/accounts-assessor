% transaction types aka action verbs

:- module(_, []).

:- use_module(library(semweb/rdf11)).
:- use_module(library(xpath)).

:- use_module('utils', []).
:- use_module('doc', [doc/3, doc_add/3, doc_new_uri/1]).

extract_action_verbs_from_bs_request(Dom) :-
	(
		xpath(Dom, //reports/balanceSheetRequest/actionTaxonomy, Taxonomy_Dom)
	->
		extract_action_taxonomy2(Taxonomy_Dom)
	;
		add_action_verbs_from_default_action_taxonomy
	).
	
add_action_verbs_from_default_action_taxonomy :-
	absolute_file_name(my_static('default_action_taxonomy.xml'), Default_Action_Taxonomy_File, [ access(read) ]),
	load_xml(Default_Action_Taxonomy_File, Taxonomy_Dom, []),
	extract_action_taxonomy2(Taxonomy_Dom).

extract_action_taxonomy2(Dom) :-
   findall(Action, xpath(Dom, //action, Action), Actions),
   maplist(add_action_verb_from_xml, Actions).
   
add_action_verb_from_xml(In) :-
	utils:fields(In, [
		id, Id,
		description, (Description, _),
		exchangeAccount, (Exchange_Account, _),
		tradingAccount, (Trading_Account, _),
		gstRatePercent, (Gst_Rate_Atom, '0'),
		gstReceivableAccount, (Gst_Receivable, _),
		gstPayableAccount, (Gst_Payable, _)
	]),
	atom_number(Gst_Rate_Atom, Gst_Rate),
	doc_new_uri(Uri),
	doc_add(Uri, rdf:type, l:action_verb),
	doc_add(Uri, l:has_id, Id),
	(nonvar(Description) -> doc_add(Uri, l:has_description, Description) ; true),
	(nonvar(Exchange_Account) -> doc_add(Uri, l:has_exchange_account, Exchange_Account) ; true),
	(nonvar(Trading_Account) -> doc_add(Uri, l:has_trading_account, Trading_Account) ; true),
	doc_add(Uri, l:has_gst_rate, Gst_Rate),
	(nonvar(Gst_Receivable) -> doc_add(Uri, l:has_gst_receivable_account, Gst_Receivable) ; true),
	(nonvar(Gst_Payable) -> doc_add(Uri, l:has_gst_payable_account, Gst_Payable) ; true).

