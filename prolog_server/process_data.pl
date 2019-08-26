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

get_requested_output_type(Options2, Output) :-
	Known_Output_Types = [json_reports_list, xbrl_instance],
	(
		member(requested_output_format=Output, Options2)
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
		Output = json_reports_list
	).

maybe_supress_generating_unique_taxonomy_urls(Options2) :-
	(
		member(relativeurls='1', Options2)
	->
		set_flag(prepare_unique_taxonomy_url, false)
	;
		true
	).

process_data(Request_File_Name, Path, Options) :-

	maybe_supress_generating_unique_taxonomy_urls(Options),
	get_requested_output_type(Options, Requested_Output_Type),

	load_xml(Path, Request_Dom, [space(remove)]),
	with_output_to(string(Output_Xml_String), process_xml_request(Request_File_Name, Request_Dom, (Reports, Output_File_Title))),
	
	response_file_name(Request_File_Name, Output_File_Name),
	my_tmp_file_name(Output_File_Name, Output_File_Path),
		
	tmp_file_url(Output_File_Name, Output_File_Url),
	tmp_file_url(Request_File_Name, Request_File_Url),

	Files = Reports.files,

	append(Files, [
		Output_File_Title:url(Output_File_Url),
		request_xml:url(Request_File_Url)
		], Files2),
	to_json(Files2, Files3),
	
	flatten([Reports.errors, Reports.warnings], Alerts2),
	findall(
		Alert, 
		(
			member(Key:Val, Alerts2), 
			atomic_list_concat([Key,':',Val], Alert)
		), 
		Alerts3
	),
	
	Json_Out = _{
		alerts:Alerts3, 
		reports:Files3
	},
	
	(
		Requested_Output_Type = xbrl_instance
	->
		(
			with_output_to(string(Response_Xml_String), print_xml_response(Json_Out, Output_Xml_String)),
			write_file(Output_File_Path, Response_Xml_String),
			write(Response_Xml_String)
		)
	;
		json_write(current_output, Json_Out)
	).

print_xml_response(Json_Out, Output_Xml_String) :-
	writeln('<?xml version="1.0"?>'), nl, nl,
	format(' <!-- files: '),
	json_write(current_output, Json_Out),
	format(' --> '),
	write(Output_Xml_String).	   
   
/* used from command line */
process_data_cmdline(File_Name, Path) :-
	bump_tmp_directory_id,
	process_data(File_Name, Path, []).
   
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

response_file_name(Request_File_Name, Response_File_Name) :-
	(
		replace_request_with_response(Request_File_Name, Response_File_Name)
	->
		true
	;
		atomic_list_concat(['response-',Request_File_Name], Response_File_Name)
	).

to_json(Reports, Reports2) :-
	findall(
		_{key:Key, val:Val}, 
		(
			member((Key:Val0), Reports),
			(
				Val0 = url(Url)
			->
				Val = _{url:Url}
			;
				Val = Val0
			)
		),
		Reports2
	).
 


/* for formatting numbers */
:- locale_create(Locale, "en_AU.utf8", []), set_locale(Locale).


/* fixme, assert the actual port in prolog_server and get that here? maybe also move this there, since we are not loading this file from the commandline anymore i think? */
:- initialization(set_server_public_url('http://localhost:8080')).
