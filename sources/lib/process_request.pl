:- use_module(library(archive)).
:- use_module(library(sgml)).
%:- use_module(library(prolog_stack)).


:- [process_request_loan].
:- [process_request_ledger].
:- [process_request_livestock].
%:- use_module(process_request_investment, []).
:- [process_request_car].
% :- [process_request_hirepurchase_new].
:- [process_request_depreciation_new].


/* for formatting numbers */ /* not sure if still used */
:- locale_create(Locale, "en_AU.utf8", []), set_locale(Locale).

:- dynamic subst/2.

/* fixme, assert the actual port in prolog_server and get that here? maybe also move this there, since we are not loading this file from the commandline anymore i think? */
%:- initialization(set_server_public_url('http://localhost:7778')).

process_request_rpc_calculator(Dict) :-
	doc_init,
	'='(Request_uri, $>atom_string(<$, Dict.request_uri)),
	'='(Result_uri, $>atomic_list_concat([Dict.rdf_namespace_base, 'results/', Dict.result_tmp_directory_name])),
	'='(Result_data_uri_base, $>atomic_list_concat([Result_uri, '/'])),
	'='(Request_data_uri_base, $>atomic_list_concat([Request_uri, '/request_data/'])),
	'='(Request_data_uri, $>atomic_list_concat([Request_data_uri_base, 'request'])),

	maplist(doc_add(Result_uri, l:rdf_explorer_base), Dict.rdf_explorer_bases),
	doc_add(Request_uri, rdf:type, l:'Request'),
	doc_add(Request_uri, l:has_result, Result_uri),
	doc_add(Request_uri, l:has_request_data, Request_data_uri),
	doc_add(Request_uri, l:has_request_data_uri_base, Request_data_uri_base),
	doc_add(Result_uri, rdf:type, l:'Result'),
	doc_add(Result_uri, l:has_result_data_uri_base, Result_data_uri_base),

	findall(
		loc(absolute_path, P),
		member(P, Dict.request_files),
		Request_Files),
	(	Request_Files = [Dir]
	->	resolve_directory(Dir, Request_Files2)
	;	Request_Files2 = Request_Files),

	set_unique_tmp_directory_name(loc(tmp_directory_name, Dict.result_tmp_directory_name)),
	set_server_public_url(Dict.server_url),
	(Request_Files2 = [] -> throw_string('no request files.') ; true),
	process_request([], Request_Files2).

process_request(Options, File_Paths) :-
	maybe_supress_generating_unique_taxonomy_urls(Options),
	%_ is 1 / 0,
	(	current_prolog_flag(die_on_error, true)
	->	(
			process_multifile_request(File_Paths),
			Exception = none
		)
	;	(
			catch_with_backtrace(
				(process_multifile_request(File_Paths) -> true ; throw(failure)),
				E,
				Exception = E
			)
		)
	),
	(	Exception \= none
	->	handle_processing_exception(Exception)
	;	true),
	process_request2.

enrich_exception_with_ctx_dump(E, E2) :-
	(	user:exception_ctx_dump(Ctx_list)
	->	(
			context_string(Ctx_list,Ctx_str),
			E2 = with_processing_context(Ctx_str, E)
		)
	;	E2 = E).

reestablish_doc :-
	(	user:exception_doc_dump(G,Ng)
	->	(
			b_setval(the_theory, G),
			b_setval(the_theory_nonground, Ng)
		)
	;	true).

handle_processing_exception(E) :-
	enrich_exception_with_ctx_dump(E, E2),
	reestablish_doc,
	format_exception_into_alert_string(E2, Str, Html),
	add_alert('error', Str, Alert_uri),
	(	Html \= ''
	->	doc_add(Alert_uri, l:has_html, Html)
	;	true).

format_exception_into_alert_string(E, Str, Html) :-
	(	E = with_processing_context(C,E2)
	->	Context_str = C
	;	(
			Context_str = '',
			E2 = E
		)
	),
	(	E2 = error(Msg0,Stacktrace)
	->	(	nonvar(Stacktrace)
		->	format(string(Stacktrace_str),'~p',[Stacktrace])
		;	Stacktrace_str = '')
	;	(
			Stacktrace_str = '',
			E2 = Msg0
		)
	),
	(	Msg0 = msg(Msg1)
	->	true
	;	Msg1 = Msg0),
	(	Msg1 = with_html(Msg,Html)
	->	true
	;	(
			Html = '',
			Msg = Msg1
		)
	),
	format(string(Str ),'~w~n~n~w~n~n~w~n',[Context_str, $>stringize(Msg), Stacktrace_str]).


process_request2 :-
	'make "all files" report entry',
	collect_alerts(Alerts3, Alerts_html),
	make_json_report(Alerts3, alerts_json),
	make_alerts_report(Alerts_html),
	make_doc_dump_report,
	json_report_entries(Files3),

	Json_Out = _{alerts:Alerts3, reports:Files3},
	absolute_tmp_path(loc(file_name,'response.json'), Json_Response_File_Path),
	dict_json_text(Json_Out, Response_Json_String),
	write_file(Json_Response_File_Path, Response_Json_String),
	writeln(Response_Json_String),

	(make_zip->true;true).

'make "all files" report entry' :-
	report_file_path(loc(file_name, ''), Tmp_Dir_Url, _),
	add_report_file(-100,'all', 'all files', Tmp_Dir_Url).


make_doc_dump_report :-
	save_doc.

json_report_entries(Out) :-
	findall(
		report_file(Priority, Title, Key, Url),
		get_report_file(Priority, Title, Key, Url),
		Files0
	),
	sort(0, @>=, Files0, Files1),
	findall(
		Json,
		(
			member(report_file(_, Title, Key, Url), Files1),
			(format_json_report_entry(Key, Title, Url, Json) -> true ; throw(error))
		),
		Out
	).


format_json_report_entry(Key, Title, Url, Json) :-
	Json0 = _{key:Key, title:Title, val:_{url:Url}},
	(	Key == "response.n3"     %_{name:'response', format:'n3'}
	->	(
			% inline response.n3 into the result json
			tmp_file_path_from_something(loc(_,Url), loc(absolute_path,P)),
			read_file_to_string(P, Contents, []),
			Json = Json0.put(contents,Contents)
		)
	% just url's for all the rest
	;	Json = Json0).

collect_alerts(Alerts_text, Alerts_html) :-
	findall(
		Alert_text,
		(
			get_alert(Key,Msg0,_),
			!alert_to_string(Key, Msg0, Alert_text)
		),
		Alerts_text
	),
	findall(
		Alert_html,
		(
			get_alert(Key,Msg0,Uri),
			(	doc(Uri,l:has_html,Alert_html)
			->	true
			;	!alert_to_html(Key, Msg0, Alert_html))
		),
		Alerts_html
	).

 alert_to_string(Key, Msg0, Alert) :-
	(Msg0 = error(msg(Msg),_) -> true ; Msg0 = Msg),
	(atomic(Msg) -> Msg2 = Msg ; term_string(Msg, Msg2)),
	atomic_list_concat([Key,': ',Msg2], Alert).

 alert_to_html(Key, Msg0, Alert) :-
	(Msg0 = error(msg(Msg),_) -> true ; Msg0 = Msg),
	% html?
	(	Msg = html(Msg2)
	->	true
	;	atomic(Msg) -> Msg2 = Msg ; term_string(Msg, Msg2)),
	Alert = p([h4([$>atom_string(<$, $>term_string(Key)),': ']),pre([Msg2])]).

make_alerts_report(Alerts_Html) :-
	(	Alerts_Html = []
	->	Alerts_Html2 = ["no alerts."]
	;	Alerts_Html2 = Alerts_Html),
	add_report_page_with_body(10,alerts, $>flatten([h3([alerts, ':']), Alerts_Html2]), loc(file_name,'alerts.html'), alerts_html).


process_multifile_request(File_Paths) :-
	debug(tmp_files, "process_multifile_request(~w)~n", [File_Paths]),
	(	accept_request_file(File_Paths, Xml_Tmp_File_Path, xml)
	->	!load_request_xml(Xml_Tmp_File_Path, Dom)
	;	true),

	(	accept_request_file(File_Paths, Rdf_Tmp_File_Path, n3)
	->	(
			!debug(tmp_files, "done accept_request_file(~w, ~w, n3)~n", [File_Paths, Rdf_Tmp_File_Path]),
			!load_request_rdf(Rdf_Tmp_File_Path, G),
			!debug(tmp_files, "RDF graph: ~w~n", [G]),
			!request(Request),
			!doc(Request, l:has_request_data_uri_base, Request_data_uri_base),
			!doc_from_rdf(G, 'https://rdf.lodgeit.net.au/v1/excel_request#', Request_data_uri_base),
			!check_request_version
			%doc_input_to_chr_constraints
		)
	;	true),
	(	process_rdf_request
	;	(
			!ground(Dom),
			(xpath(Dom, //reports, _)
			->	!process_xml_request(Xml_Tmp_File_Path, Dom)
			;	throw_string('<reports> tag not found'))
		)
	).

/* only done for requests that include a rdf file */
check_request_version :-
	Expected = "2",
	!request_data(D),
	(	doc(D, l:client_version, V)
	->	(	V = Expected
		->	true
		;	throw_string(['incompatible client version, expected: ', Expected]))
	;	throw_string(['l:client_version not specified, must be: ', Expected])).

accept_request_file(File_Paths, Path, Type) :-
	debug(tmp_files, "accept_request_file(~w, ~w, ~w)~n", [File_Paths, Path, Type]),
	member(Path, File_Paths),
	debug(tmp_files, "member(~w, ~w)~n", [Path, File_Paths]),
	tmp_file_path_to_url(Path, Url),
	debug(tmp_files, "tmp_file_path_to_url(~w, ~w)~n", [Path, Url]),
	(	loc_icase_endswith(Path, ".xml")
	->	(
			add_report_file(-20,'request_xml', 'request_xml', Url),
			Type = xml
		)
	;	(	loc_icase_endswith(Path, "n3")
		->	(
				add_report_file(-20,'request_n3', 'request_n3', Url),
				Type = n3
			)
		)
	).

load_request_xml(loc(absolute_path,Xml_Tmp_File_Path), Dom) :-
	load_structure(Xml_Tmp_File_Path, Dom, [dialect(xmlns), space(remove), keep_prefix(true)]).

load_request_rdf(loc(absolute_path, Rdf_Tmp_File_Path), G) :-

	rdf_create_bnode(G),
	rdf_load(Rdf_Tmp_File_Path, [
		graph(G),
		anon_prefix(bn),
		on_error(error)
	]),
	%findall(_, (rdf(S,P,O),format(user_error, 'raw_rdf:~q~n',(S,P,O))),_),
	true.

process_rdf_request :-
	debug(requests, "process_rdf_request~n", []),
	(	%process_request_hirepurchase_new;
		process_request_ledger;
		process_request_depreciation_new),
	make_rdf_report.



process_xml_request(File_Path, Dom) :-
/*+   request_xml_to_doc(Dom),*/
	(process_request_car(File_Path, Dom);
	(process_request_loan(File_Path, Dom);
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

resolve_directory(Path, File_Paths) :-
	Path = loc(absolute_path, Path_Value),
	(	exists_directory(Path_Value)
	->	/* invoked with a directory */
		directory_real_files(Path, File_Paths)
	;	/* invoked with a file */
		File_Paths = [Path]),
	(File_Paths = [] -> throw('no files found') ; true).






/*	rdf_register_prefix(pid, ':'),
	doc_add(pid, rdf:type, l:request),
	doc_add(pid, rdfs:comment, "processing id - the root node for all data pertaining to processing current request. Also looked up by being the only object of type l:request, but i'd outphase that.").
*/
