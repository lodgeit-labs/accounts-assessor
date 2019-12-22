

:- use_module(library(archive)).
:- use_module(library(sgml)).
:- use_module(library(semweb/turtle)).

:- [process_request_loan].
:- [process_request_ledger].
%:- use_module(process_request_livestock, []).
%:- use_module(process_request_investment, []).
:- use_module(process_request_car, []).
:- [process_request_hirepurchase_new].
:- [process_request_depreciation_new].


/* for formatting numbers */
:- locale_create(Locale, "en_AU.utf8", []), set_locale(Locale).

/* fixme, assert the actual port in prolog_server and get that here? maybe also move this there, since we are not loading this file from the commandline anymore i think? */
:- initialization(set_server_public_url('http://localhost:8080')).

/* takes either a xml request file, or a directory expected to contain a xml request file, an n3 file, or both */
process_request_cmdline(Path) :-
	(
		(	exists_directory(Path),
			directory_real_files(Path, File_Paths)),
			(File_Paths = [] -> throw('no files found') ; true)
	->		true
	;		File_Paths = [Path]),
	bump_tmp_directory_id,
	copy_request_files_to_tmp(File_Paths, _),
	process_request([], File_Paths).

process_request_http(Options, Parts) :-
	member(_=file(_, F1), Parts),
	once(member(F1, File_Paths)),
	(	member(file2=file(_, F2), Parts)
	->	once(member(F2, File_Paths))
	;	true),
	once(append(File_Paths, [], File_Paths)),
	process_request(Options, File_Paths).

process_request(Options, File_Paths) :-
	doc_init,
	maybe_supress_generating_unique_taxonomy_urls(Options),
	process_mulitifile_request(File_Paths),
	report_file_path('', Tmp_Dir_Url, _),
	report_entry('all files', Tmp_Dir_Url, 'all'),
	findall(
		_{key:Title, val:_{url:Url}, id:Id},
		get_report_file(Id, Title, Url),
		Files3),
	findall(
		Alert,
		(
			get_alert(Key,Val),
			(
				(
					pretty_term_string(Val, Val_Str),
					atomic_list_concat([Key,':',Val_Str], Alert)
				)
				->	true
				;	throw(xxx)
			)
		),
		Alerts3
	),
	Json_Out = _{
		alerts:Alerts3,
		reports:Files3
	},

	absolute_tmp_path('response.json', Json_Response_File_Path),
	dict_json_text(Json_Out, Response_Json_String),
	write_file(Json_Response_File_Path, Response_Json_String),

	get_requested_output_type(Options, Requested_Output_Type),
	(	Requested_Output_Type = xml
	->	(
			tmp_file_path_from_url(Json_Out.reports.response_xml, Xml_Path),
			print_file(Xml_Path)
		)
	;	writeln(Response_Json_String)),
	make_zip.

process_mulitifile_request(File_Paths) :-
	(	xml_request(File_Paths, Xml_Tmp_File_Path)
	->	load_structure(Xml_Tmp_File_Path, Dom, [dialect(xmlns), space(remove), keep_prefix(true)])
	;	true),
	(	rdf_request_file(File_Paths, Rdf_Tmp_File_Path)
	->	load_request_rdf(Rdf_Tmp_File_Path, G)
	;	true),
	doc_from_rdf(G),
	(	process_rdf_request
	;	(
			xpath(Dom, //reports, _)
			->	process_xml_request(Xml_Tmp_File_Path, Dom)
			;	throw_string('<reports> tag not found'))).

xml_request(File_Paths, Xml_Tmp_File_Path) :-
	member(Xml_Tmp_File_Path, File_Paths),
	icase_endswith(Xml_Tmp_File_Path, ".xml"),
	tmp_file_path_to_url(Xml_Tmp_File_Path, Url),
	report_entry('request_xml', Url, 'request_xml').

rdf_request_file(File_Paths, Rdf_Tmp_File_Path) :-
	member(Rdf_Tmp_File_Path, File_Paths),
	icase_endswith(Rdf_Tmp_File_Path, "n3"),
	tmp_file_path_to_url(Rdf_Tmp_File_Path, Url),
	report_entry('request_n3', Url, 'request_n3').

load_request_rdf(Rdf_Tmp_File_Path, G) :-
	rdf_create_bnode(G),
	rdf_load(Rdf_Tmp_File_Path, [graph(G), anon_prefix(bn)]),
	findall(_, (rdf(S,P,O),writeq(('raw_rdf:',S,P,O)),nl),_).

process_rdf_request :-
	(	process_request_hirepurchase_new;
		process_request_depreciation_new).

process_xml_request(File_Path, Dom) :-
	exclude_file_location_from_filename(File_Path, File_Name),
	(process_request_car:process(File_Name, Dom);
	(process_request_loan(File_Name, Dom);
	(process_request_ledger(File_Name, Dom)
	%(process_request_livestock:process(File_Name, Dom);
	%(process_request_investment:process(File_Name, Dom);
	%(process_request_depreciation_old:process(File_Name, Dom)
	))).


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

print_xml_report(Json_Out, Output_Xml_String) :-
	writeln('<?xml version="1.0"?>'), nl, nl,
	format('<!-- reports: '),
	json_write(current_output, Json_Out),
	format(' -->'),
	write(Output_Xml_String).

/* http uri parameter -> prolog flag */
maybe_supress_generating_unique_taxonomy_urls(Options2) :-
	(	member(relativeurls='1', Options2)
	->	set_flag(prepare_unique_taxonomy_url, false)
	;	true).

response_file_name(Request_File_Name, Response_File_Name) :-
	(	replace_request_with_response(Request_File_Name, Response_File_Name)
	->	true
	;	atomic_list_concat(['response-',Request_File_Name], Response_File_Name)).

reports(Reports, Output_File_Title) :-
	Output_File_Title = 'response.n3',
	doc_to_rdf(Rdf_Graph),
	report_file_path(Output_File_Title, _Report_Url, Report_File_Path),
	rdf_save(Report_File_Path, [graph(Rdf_Graph), sorted(true)]),
	Reports = _{files:[Report_File_Path], alerts:[]}.







/*
process_with_output(Request_File_Name, Request_Dom) :-
	catch_maybe_with_backtrace(
		process_xml_request(Request_File_Name, Request_Dom, (Reports, Xml_Response_Title)),
		Error,
		(
			print_message(error, Error),
			throw(Error)
		)
	).
*/