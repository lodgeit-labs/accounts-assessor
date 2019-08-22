% ===================================================================
% Project:   LodgeiT
% File:      process_data.pl
% Author:    Rolf Schwitter
% Date:      2019-06-08
% ===================================================================

% -------------------------------------------------------------------
% Modules
% -------------------------------------------------------------------

:- use_module(library(xpath)).
:- use_module(library(http/http_host)).

:- use_module('../lib/files', [
		bump_tmp_directory_id/0,
		set_server_public_url/1
]).
:- use_module('../lib/utils', [
		throw_string/1
]).

:- use_module(loan/process_xml_loan_request, [process_xml_loan_request/2]).
:- use_module(ledger/process_xml_ledger_request, [process_xml_ledger_request/2]).
:- use_module(livestock/process_xml_livestock_request, [process_xml_livestock_request/2]).
:- use_module(investment/process_xml_investment_request, [process_xml_investment_request/2]).
:- use_module(car_request/process_xml_car_request, [process_xml_car_request/2]).
:- use_module(depreciation/process_xml_depreciation_request, [process_xml_depreciation_request/2]).




get_requested_output_type(Request, Requested_Output_Type),
	Known_Output_Types = [json_reports_list, xbrl],
	(
		member(search([output=Output]), Request)
	->
		(
			member(Output, Known_Output_Types)
		->
			true
		;
			(
				term_string(Known_Output_Types, Known_Output_Types_Str),
				atomic_list_concat(['output parameter must be one of ', Known_Output_Types_Str], Msg),
				throw(http_reply(bad_request(string(Msg))))
			)
		)
	;
		Requested_Output_Type = json_reports_list,
	).

maybe_supress_generating_unique_taxonomy_urls(Request) :-
	(
		member(search([relativeurls='1']), Request)
	->
		set_flag(prepare_unique_taxonomy_url, false)
	;
		true
	).

	
% -------------------------------------------------------------------
% process_data/3
% -------------------------------------------------------------------

process_data(FileName, Path, Request) :-
	http_public_host_url(Request, Server_Public_Url),
	set_server_public_url(Server_Public_Url),

	get_requested_output_type(Request, Requested_Output_Type),
	maybe_supress_generating_unique_taxonomy_urls(Request),

	format('Content-type: text/xml~n~n'),
	process_data1(FileName, Path).
   % writeq(DOM),
   % write(FileName),
   % write(Path).

process_data1(FileName, Path) :-
   load_xml(Path, DOM, [space(remove)]),
   process_xml_request(FileName, DOM).

/* used from command line */
process_data2(FileName, Path) :-
	bump_tmp_directory_id,
	process_data1(FileName, Path).
   
% -------------------------------------------------------------------
% process_xml_request/2
% -------------------------------------------------------------------

process_xml_request(FileName, DOM) :-
   (
      xpath(DOM, //reports, _)
   ->
      true
   ;
      throw_string('<reports> tag not found')
   ),
   (process_xml_car_request(FileName, DOM) -> true;
   (process_xml_loan_request(FileName, DOM) -> true;
   (process_xml_ledger_request(FileName, DOM) -> true;
   (process_xml_livestock_request(FileName, DOM) -> true;
   (process_xml_investment_request(FileName, DOM) -> true;
   (process_xml_depreciation_request(FileName, DOM) -> true)))))).


/* for formatting numbers */
:- locale_create(Locale, "en_AU.utf8", []), set_locale(Locale).


/* fixme, assert the actual port in prolog_server and get that here? maybe also move this there, since we are not loading this file from the commandline anymore i think? */
:- initialization(set_server_public_url('http://localhost:8080')).
