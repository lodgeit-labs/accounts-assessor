:- use_module(library(xpath)).
:- use_module(library(archive)).
:- use_module(library(sgml)).

:- use_module(process_xml_loan_request).
:- use_module(process_xml_ledger_request).
:- use_module(process_xml_livestock_request).
:- use_module(process_xml_investment_request).
:- use_module(process_xml_car_request).
:- use_module(process_xml_depreciation_request).

:- use_module('files', [
		bump_tmp_directory_id/0,
		set_server_public_url/1,
		replace_request_with_response/2,
		write_file/2,
		tmp_file_url/2
]).
:- use_module(library(xbrl/utils)).
:- use_module('doc', []).


/* used from command line */
/*
process_data_cmdline(Path) :-
	bump_tmp_directory_id,
	files:exclude_file_location_from_filename(Path, Request_Fn),
	absolute_tmp_path(Request_Fn, Tmp_Request_File_Path),
	copy_file(Path, Tmp_Request_File_Path),
	process_request_files(Path, Path, []).
*/

/* used from http server */
process_data(Options, Parts) :-
	maybe_supress_generating_unique_taxonomy_urls(Options),

	process_with_theory(Parts, Request_File_Name, Reports, Output_File_Title, Output_Xml_String),

	response_file_name(Request_File_Name, Output_File_Name),
	absolute_tmp_path(Output_File_Name, Output_File_Path),
	absolute_tmp_path('response.json', Json_Response_File_Path),

	tmp_file_url(Output_File_Name, Output_File_Url),
	tmp_file_url(Request_File_Name, Request_File_Url),
	(get_dict(files, Reports, Files) -> true; Files  = []),
	(get_dict(errors, Reports, Errors) -> true; Errors  = []),
	(get_dict(warnings, Reports, Warnings) -> true; Warnings  = []),

	files:report_file_path('', Tmp_Dir_Url, _),

	flatten([
		Files,
		_{key:Output_File_Title, val:_{url:Output_File_Url}, id:response_xml},
		_{key:request_xml, val:_{url:Request_File_Url}, id:request_xml},
		_{key:'all files', val:_{url:Tmp_Dir_Url}, id:all}
	], Files3),

	flatten([Errors, Warnings], Alerts2),
	findall(
		Alert,
		(
			member(KV, Alerts2),
			((Key:Val) = KV -> true ; throw('internal error 1')),
			atomic_list_concat([Key,':',Val], Alert)
		),
		Alerts3
	),

	Json_Out = _{
		alerts:Alerts3,
		reports:Files3
	},
	with_output_to(string(Response_Xml_String), print_xml_report(Json_Out, Output_Xml_String)),
	write_file(Output_File_Path, Response_Xml_String),
	with_output_to(string(Response_Json_String), json_write(current_output, Json_Out)),
	write_file(Json_Response_File_Path, Response_Json_String),
	make_zip,
	get_requested_output_type(Options, Requested_Output_Type),
	(
		Requested_Output_Type = xml
	->
		(
			writeln(Response_Xml_String),
			debug(process_data, 'returning xml', [])
		)
	;
		(
			writeln(Response_Json_String),
			debug(process_data, 'returning json', [])
		)
	).

icase_endswith(String, End) :-
	string_lower(String, String2),
	sub_string(String2, _,_,0,End).

process_with_theory(Parts, Request_File_Name, Reports, Output_File_Title, Output_Xml_String) :-
	member(file=file(_, Xml_Tmp_File_Path), Parts),
	files:exclude_file_location_from_filename(Xml_Tmp_File_Path, Request_File_Name),
	icase_endswith(Xml_Tmp_File_Path, ".xml"),
	load_structure(Xml_Tmp_File_Path, Request_Dom, [dialect(xmlns), space(remove), keep_prefix(true)]),
	(
		(
			gtrace,
			member(file2=file(_, Rdf_Tmp_File_Path), Parts),
			icase_endswith(Rdf_Tmp_File_Path, ".rdf.xml")
		)
	->
		
	;
		gtrace,writeq(xx)
	),

	/*
	i'm storing some data in the 'doc' rdf-like database, only as an experiment for now.
	livestock and action verbs exclusively, some other data in parallel with passing them around in variables
	*/
	doc_core:doc_clear,
	doc:doc_new_uri(R),
	doc:doc_add(R, rdf:a, l:request),
	process_with_output(Request_File_Name, Request_Dom, Reports, Output_File_Title, Output_Xml_String).
	/*
	no cleanup for the doc database needed
	*/

process_with_output(Request_File_Name, Request_Dom, Reports, Output_File_Title, Output_Xml_String) :-
	with_output_to(
		string(Output_Xml_String),
		catch_maybe_with_backtrace(
			prolog_server:process_xml_request(Request_File_Name, Request_Dom, (Reports, Output_File_Title)),
			Error,
			(
				print_message(error, Error),
				throw(Error)
			)
		)
	).


/* */
process_xml_request(File_Name, Dom, (Report_Files, Response_Title)) :-
	(
		xpath(Dom, //reports, _)
	->
		true
	;
		throw_string('<reports> tag not found')
	),
	(process_xml_car_request:process_xml_car_request(File_Name, Dom, Report_Files);
	(process_xml_loan_request:process_xml_loan_request(File_Name, Dom, Report_Files);
	(process_xml_ledger_request:process_xml_ledger_request(File_Name, Dom, Report_Files) -> Response_Title = 'xbrl instance';
	(process_xml_livestock_request:process_xml_livestock_request(File_Name, Dom, Report_Files);
	(process_xml_investment_request:process_xml_investment_request(File_Name, Dom, Report_Files);
	(process_xml_depreciation_request:process_xml_depreciation_request(File_Name, Dom, Report_Files))))))),
	(
		var(Response_Title)
	->
		Response_Title = 'xml response'
	;
		true
	).




make_zip :-
	files:my_request_tmp_dir(Tmp_Dir),
	atomic_list_concat([Tmp_Dir, '.zip'], Zip_Fn),
	atomic_list_concat(['tmp/', Zip_Fn], Zip_In_Tmp),
	archive_create(Zip_In_Tmp, [Tmp_Dir], [format(zip), directory('tmp')]),
	atomic_list_concat(['mv ', Zip_In_Tmp, ' tmp/', Tmp_Dir], Cmd),
	shell(Cmd, _).

/* for formatting numbers */
:- locale_create(Locale, "en_AU.utf8", []), set_locale(Locale).


/* fixme, assert the actual port in prolog_server and get that here? maybe also move this there, since we are not loading this file from the commandline anymore i think? */
:- initialization(set_server_public_url('http://localhost:8080')).

get_requested_output_type(Options2, Output) :-
	Known_Output_Types = [json_reports_list, xml],
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
				atomic_list_concat(['requested_output_format must be one of ', Known_Output_Types_Str], Msg),
				throw(http_reply(bad_request(string(Msg))))
			)
		)
	;
		Output = json_reports_list
	).

/* http uri parameter -> prolog flag */
maybe_supress_generating_unique_taxonomy_urls(Options2) :-
	(
		member(relativeurls='1', Options2)
	->
		set_flag(prepare_unique_taxonomy_url, false)
	;
		true
	).

response_file_name(Request_File_Name, Response_File_Name) :-
	(	replace_request_with_response(Request_File_Name, Response_File_Name)
	->	true
	;	atomic_list_concat(['response-',Request_File_Name], Response_File_Name)).


print_xml_report(Json_Out, Output_Xml_String) :-
	writeln('<?xml version="1.0"?>'), nl, nl,
	format('<!-- reports: '),
	json_write(current_output, Json_Out),
	format(' -->'),
	write(Output_Xml_String).
