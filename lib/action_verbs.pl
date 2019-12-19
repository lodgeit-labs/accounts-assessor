% transaction types aka action verbs

:- module(_, []).

:- use_module(library(semweb/rdf11)).
:- use_module(library(xpath)).

:- use_module(library(xbrl/utils), []).
:- use_module('doc', []).

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
   maplist(add_action_verb_from_xml, Actions),
   add_builtin_action_verbs.
   
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
	doc:doc_new_uri(Uri),
	doc:doc_add(Uri, rdf:type, l:action_verb),
	doc:doc_add(Uri, l:has_id, Id),
	(nonvar(Description) -> doc:doc_add(Uri, l:has_description, Description) ; true),
	(nonvar(Exchange_Account) -> doc:doc_add(Uri, l:has_counteraccount, Exchange_Account) ; true),
	(nonvar(Trading_Account) -> doc:doc_add(Uri, l:has_trading_account, Trading_Account) ; true),
	doc:doc_add(Uri, l:has_gst_rate, Gst_Rate),
	(nonvar(Gst_Receivable) -> doc:doc_add(Uri, l:has_gst_receivable_account, Gst_Receivable) ; true),
	(nonvar(Gst_Payable) -> doc:doc_add(Uri, l:has_gst_payable_account, Gst_Payable) ; true).

add_builtin_action_verbs :-
	doc:doc_add(l:livestock_sale, rdf:type, l:action_verb),
	doc:doc_add(l:livestock_sale, l:has_id, 'Livestock_Sale'),
	doc:doc_add(l:livestock_purchase, rdf:type, l:action_verb),
	doc:doc_add(l:livestock_purchase, l:has_id, 'Livestock_Purchase').

action_verb(Action_Verb) :-
	doc:docm(Action_Verb, rdf:type, l:action_verb).
