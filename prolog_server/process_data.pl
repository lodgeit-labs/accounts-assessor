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
:- use_module(library(http/json)).

:- use_module(loan/process_xml_loan_request, [process_xml_loan_request/2]).
:- use_module(ledger/process_xml_ledger_request, [process_xml_ledger_request/3]).
:- use_module(livestock/process_xml_livestock_request, [process_xml_livestock_request/2]).
:- use_module(investment/process_xml_investment_request, [process_xml_investment_request/2]).
:- use_module(car_request/process_xml_car_request, [process_xml_car_request/2]).
:- use_module(depreciation/process_xml_depreciation_request, [process_xml_depreciation_request/2]).

:- use_module('../lib/files', [
		bump_tmp_directory_id/0,
		set_server_public_url/1,
		replace_request_with_response/2,
		write_file/2,
		tmp_file_url/2
]).
:- use_module('../lib/utils', [
		throw_string/1
]).

get_requested_output_type(Request, Requested_Output_Type) :-
	Known_Output_Types = [json_reports_list, xbrl_instance],
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
		Requested_Output_Type = json_reports_list
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

process_data(Request_File_Name, Path, Request) :-
	
	http_public_host_url(Request, Server_Public_Url),
	set_server_public_url(Server_Public_Url),

	maybe_supress_generating_unique_taxonomy_urls(Request),
	get_requested_output_type(Request, Requested_Output_Type),

	process_data1(Request_File_Name, Path, Response_Xml_String, (Report_Files, Response_Title)),
	
	response_file_name(Request_File_Name, Response_File_Name),
	my_tmp_file_name(Response_File_Name, Response_File_Path),
	write_file(Response_File_Path, Response_Xml_String),
	tmp_file_url(Response_File_Name, Response_File_Url),
	Report_Files2 = Report_Files.put(Response_Title, Response_File_Url),
	
	(
		Requested_Output_Type = xbrl_instance
	->
		(
			format('Content-type: text/xml~n~n'),
			write(Response_Xml_String)
		)
	;
		(
			format('Content-type: application/json~n~n'),
			json_write(current_output, Report_Files2)
		)
	).
	
   % writeq(Dom),
   % write(File_Name),
   % write(Path).

response_file_name(Request_File_Name, Response_File_Name) :-
	(
		replace_request_with_response(Request_File_Name, Response_File_Name)
	->
		true
	;
		atomic_list_concat(['response-',Request_File_Name], Response_File_Name)
	).
   
process_data1(File_Name, Path, Xml_String, Info) :-
	load_xml(Path, Dom, [space(remove)]),
	with_output_to(string(Xml_String), process_xml_request(File_Name, Dom, Info)).

/* used from command line */
process_data2(File_Name, Path) :-
	bump_tmp_directory_id,
	process_data1(File_Name, Path, Xml_String, _Info),
	write(Xml_String).
   
% -------------------------------------------------------------------
% process_xml_request/2
% -------------------------------------------------------------------

process_xml_request(File_Name, Dom, (Report_Files, Response_Title)) :-
	(
		xpath(Dom, //reports, _)
	->
		true
	;
		throw_string('<reports> tag not found')
	),
	(process_xml_car_request(File_Name, Dom) -> Report_Files = files{};
	(process_xml_loan_request(File_Name, Dom) -> Report_Files = files{};
	(process_xml_ledger_request(File_Name, Dom, Report_Files) -> Response_Title = 'xbrl instance';
	(process_xml_livestock_request(File_Name, Dom) -> Report_Files = files{};
	(process_xml_investment_request(File_Name, Dom) -> Report_Files = files{};
	(process_xml_depreciation_request(File_Name, Dom) -> Report_Files = files{})))))),
	(
		var(Response_Title)
	->
		Response_Title = 'xml response'
	;
		true
	).


/* for formatting numbers */
:- locale_create(Locale, "en_AU.utf8", []), set_locale(Locale).


/* fixme, assert the actual port in prolog_server and get that here? maybe also move this there, since we are not loading this file from the commandline anymore i think? */
:- initialization(set_server_public_url('http://localhost:8080')).
