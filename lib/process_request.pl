:- use_module(library(archive)).
:- use_module(library(sgml)).
:- use_module(library(semweb/turtle)).

:- [process_request_loan].
:- [process_request_ledger].
:- [process_request_livestock].
%:- use_module(process_request_investment, []).
:- [process_request_car].
:- [process_request_hirepurchase_new].
:- [process_request_depreciation_new].


/* for formatting numbers */
:- locale_create(Locale, "en_AU.utf8", []), set_locale(Locale).

/* fixme, assert the actual port in prolog_server and get that here? maybe also move this there, since we are not loading this file from the commandline anymore i think? */
%:- initialization(set_server_public_url('http://localhost:7778')).

process_request_rpc_calculator(Dict) :-
	findall(
		loc(absolute_path, P),
		member(P, Dict.request_files),
		Request_Files),
	(	Request_Files = [Dir]
	->	resolve_directory(Dir, Request_Files2)
	;	Request_Files2 = Request_Files),
	% todo options
	set_unique_tmp_directory_name(loc(tmp_directory_name, Dict.tmp_directory_name)),
	set_server_public_url(Dict.server_url),
	(Request_Files2 = [] -> throw('no files.') ; true),
	process_request([], Request_Files2).

/* takes either a xml request file, or a directory expected to contain a xml request file, an n3 file, or both */
process_request_cmdline(Path_Value0) :-
	resolve_specifier(loc(specifier, Path_Value0), Path),
	bump_tmp_directory_id,
	resolve_directory(Path, File_Paths),
	copy_request_files_to_tmp(File_Paths, _),
	process_request([], File_Paths).

resolve_directory(Path, File_Paths) :-
	Path = loc(absolute_path, Path_Value),
	(	exists_directory(Path_Value)
	->	/* invoked with a directory */
		directory_real_files(Path, File_Paths)
	;	/* invoked with a file */
		File_Paths = [Path]),
	(File_Paths = [] -> throw('no files found') ; true).

process_request_http(Options, Parts) :-
	findall(F1,	member(_=file(F1), Parts), File_Paths),
	process_request(Options, File_Paths).

process_request(Options, File_Paths) :-
	doc_init,
	maybe_supress_generating_unique_taxonomy_urls(Options),
	process_multifile_request(File_Paths),
	process_request2.

process_request2 :-
	'make "all files" report entry',
	collect_alerts(Alerts3),
	make_alerts_report(Alerts3),
	json_report_entries(Files3),

	Json_Out = _{alerts:Alerts3, reports:Files3},
	absolute_tmp_path(loc(file_name,'response.json'), Json_Response_File_Path),
	dict_json_text(Json_Out, Response_Json_String),
	write_file(Json_Response_File_Path, Response_Json_String),
	writeln(Response_Json_String),

	(make_zip->true;true).

'make "all files" report entry' :-
	report_file_path(loc(file_name, ''), Tmp_Dir_Url, _),
	report_entry('all files', Tmp_Dir_Url, 'all').

json_report_entries(Files3) :-
	findall(
		Json,
		(
			get_report_file(Key, Title, loc(absolute_url,Url)),
			(format_json_report_entry(Key, Title, Url, Json) -> true ; throw(error))
		),
		Files3
	).

format_json_report_entry(Key, Title, Url, Json) :-
	Json0 = _{key:Key, title:Title, val:_{url:Url}},
	(	Key == 'response.n3'     %_{name:'response', format:'n3'}
	->	(
			% inline response.n3 into the result json
			tmp_file_path_from_something(loc(_,Url), loc(absolute_path,P)),
			read_file_to_string(P, Contents, []),
			Json = Json0.put(contents,Contents)
		)
	% just url's for all the rest
	;	Json = Json0).

collect_alerts(Alerts3) :-
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
	).

make_alerts_report(Alerts) :-
	make_json_report(Alerts, alerts_json),
	maplist(alert_html, Alerts, Alerts_Html),
	(	Alerts_Html = []
	->	Alerts_Html2 = ['no alerts']
	;	Alerts_Html2 = Alerts_Html),
	report_page(alerts, [h3([alerts, ':']), div(Alerts_Html2)], loc(file_name,'alerts.html'), alerts_html).

alert_html(Alert, div([Alert, br([]), br([])])).


process_multifile_request(File_Paths) :-
	(	accept_request_file(File_Paths, Xml_Tmp_File_Path, xml)
	->	load_request_xml(Xml_Tmp_File_Path, Dom)
	;	true),
	(	accept_request_file(File_Paths, Rdf_Tmp_File_Path, n3)
	->	(
			load_request_rdf(Rdf_Tmp_File_Path, G),
			doc_from_rdf(G)
		)
	;	true),
	(	process_rdf_request
	;	(
			xpath(Dom, //reports, _)
			->	process_xml_request(Xml_Tmp_File_Path, Dom)
			;	throw_string('<reports> tag not found'))).

accept_request_file(File_Paths, Path, Type) :-
	member(Path, File_Paths),
	tmp_file_path_to_url(Path, Url),
	(
		loc_icase_endswith(Path, ".xml")
	->	(
			report_entry('request_xml', Url, 'request_xml'),
			Type = xml
		)
	;	loc_icase_endswith(Path, "n3")
	->	(
			report_entry('request_n3', Url, 'request_n3'),
			Type = n3
		)).

load_request_xml(loc(absolute_path,Xml_Tmp_File_Path), Dom) :-
	load_structure(Xml_Tmp_File_Path, Dom, [dialect(xmlns), space(remove), keep_prefix(true)]).

load_request_rdf(loc(absolute_path, Rdf_Tmp_File_Path), G) :-
	rdf_create_bnode(G),
	rdf_load(Rdf_Tmp_File_Path, [graph(G), anon_prefix(bn), on_error(error)]),
	%findall(_, (rdf(S,P,O),format(user_error, 'raw_rdf:~q~n',(S,P,O))),_),
	true.

make_rdf_report :-
	Title = 'response.n3',
	doc_to_rdf(Rdf_Graph),
	report_file_path(loc(file_name, Title), Url, loc(absolute_path,Path)),
	add_report_file(Title, Title, Url),
	Url = loc(absolute_url, Url_Value),
	rdf_save_turtle(Path, [graph(Rdf_Graph), sorted(true), base(Url_Value), canonize_numbers(true), abbreviate_literals(false), prefixes([rdf,rdfs,xsd,l,livestock])]).

/*




*/

process_rdf_request :-
	(	process_request_hirepurchase_new;
		process_request_depreciation_new),
	!,
	make_rdf_report.

process_xml_request(File_Path, Dom) :-
	(process_request_car(File_Path, Dom);
	(process_request_loan(File_Path, Dom);
	(process_request_ledger(File_Path, Dom);
	(process_request_livestock(File_Path, Dom);
	%(process_request_investment:process(File_Path, Dom);
	false
	)))).


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
