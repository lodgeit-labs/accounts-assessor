% transaction types aka action verbs

:- module(_, []).

:- use_module(library(semweb/rdf11)).
:- use_module(library(xpath)).

:- use_module('utils', []).

:- rdf_register_prefix(l, 'https://lodgeit.net.au#').

request_graph(G) :-
	my_request_tmp_dir(G).

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
		gstRatePercent, (Gst_Rate, 0),
		gstReceivableaccount, (Gst_Receivable, _),
		gstPayableaccount, (Gst_Payable, _)
	]),
	rdf_create_bnode(Uri), % will see if this causes any problems
	rdf_assert(Uri, rdf:type, l:action_verb),
	rdf_assert(Uri, l:has_id, Id),
	(nonvar(Description) -> rdf_assert(Uri, l:has_description, Description) ; true),
	(nonvar(Exchange_Account) -> rdf_assert(Uri, l:has_exchange_account, Exchange_Account) ; true),
	(nonvar(Trading_Account) -> rdf_assert(Uri, l:has_trading_account, Trading_Account) ; true),
	rdf_assert(Uri, l:has_gst_rate, Gst_Rate),
	(nonvar(Gst_Receivable) -> rdf_assert(Uri, l:has_gst_receivable_account, Gst_Receivable) ; true),
	(nonvar(Gst_Payable) -> rdf_assert(Uri, l:has_gst_payable_account, Gst_Payable) ; true).

