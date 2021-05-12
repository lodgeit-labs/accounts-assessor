:- use_module(library(archive)).
:- use_module(library(sgml)).
%:- use_module(library(prolog_stack)).


:- [process_request_loan].
:- [process_request_ledger].
:- [process_request_livestock].
%:- use_module(process_request_investment, []).
:- [process_request_car].
% :- [process_request_hirepurchase_new].
:- ['../depr/src/process_request_depreciation_new'].


/* for formatting numbers */ /* not sure if still used */
:- locale_create(Locale, "en_AU.utf8", []), set_locale(Locale).


 process_request_rpc_calculator(Dict) :-
	set_unique_tmp_directory_name(loc(tmp_directory_name, Dict.result_tmp_directory_name)),
	doc_init,
	init_doc_dump_server,
	context_trace_init_trail_0,
	'='(Request_uri, $>atom_string(<$, Dict.request_uri)),
	'='(Request_data_uri_base, $>atomic_list_concat([Request_uri, '/request_data/'])),
	'='(Request_data_uri, $>atomic_list_concat([Request_data_uri_base, 'request'])),
	'='(Result_uri, $>atomic_list_concat([Dict.rdf_namespace_base, 'results/', Dict.result_tmp_directory_name])),
	'='(Result_data_uri_base, $>atomic_list_concat([Result_uri, '/'])),

	maplist(doc_add(Result_uri, l:rdf_explorer_base), Dict.rdf_explorer_bases),
	doc_add(Request_uri, rdf:type, l:'Request'),
	doc_add(Request_uri, l:has_result, Result_uri),
	doc_add(Request_uri, l:has_request_data, Request_data_uri),
	doc_add(Result_uri, rdf:type, l:'Result'),
	doc_add(Result_uri, l:has_result_data_uri_base, Result_data_uri_base),

	findall(
		loc(absolute_path, P),
		member(P, Dict.request_files),
		Request_Files
	),
	(	Request_Files = [Dir]
	->	resolve_directory(Dir, Request_Files2)
	;	Request_Files2 = Request_Files),

	set_server_public_url(Dict.server_url),
	(	Request_Files2 = []
	->	throw_string('no request files.')
	;	true),

	'make task_directory report entry',

	findall(_,process_request(Request_data_uri_base, Request_Files2),_),

	(cf(make_zip)->true;true).


process_request(Request_data_uri_base, File_Paths) :-
	(	current_prolog_flag(die_on_error, true)
	->	(
			process_multifile_request(Request_data_uri_base,File_Paths),
			Exception = none
		)
	;	(
			catch_with_backtrace(
				process_multifile_request(Request_data_uri_base,File_Paths),
				E,
				Exception = E
			)
		)
	),
	(	Exception \= none
	->	!handle_processing_exception(Exception)
	;	true),
	!process_request2.

process_request2 :-
	!collect_alerts(Alerts3, Alerts_html),
	!make_json_report(Alerts3, alerts_json),
	!make_alerts_report(Alerts_html),
	!make_doc_dump_report,
	!cf(make_context_trace_report),
	!cf(json_report_entries(Files3)),
	Json_Out = _{alerts:Alerts3, reports:Files3},
	!cf(make_json_report(Json_Out,'response.json',_)),
	!cf(dict_json_text(Json_Out, Response_Json_String)),
	writeln(Response_Json_String),
	flush_output,
	%gtrace,
	ct(done).


get_exception_ctx_dump_string(Ctx_str) :-
	(	user:exception_ctx_dump(Ctx_list)
	->	context_string(Ctx_list,Ctx_str)
	;	fail).


enrich_exception_with_ctx_dump(E, E2) :-
	(	context_string(Ctx_str)
	->	E2 = with_processing_context(Ctx_str, E)
	;	E2 = E).

reestablish_doc :-
	(	user:exception_doc_dump(G,Ng)
	->	(
			b_setval(the_theory, G),
			b_setval(the_theory_nonground, Ng)
		)
	;	true).

 handle_processing_exception(E) :-
	reestablish_doc,
	handle_processing_exception2(E).

handle_processing_exception2(E) :-
	enrich_exception_with_ctx_dump(E, E2),
	format_exception_into_alert_string(E2, Str, Html),
	add_alert('error', Str, Alert_uri),
	(	Html \= ''
	->	doc_add(Alert_uri, l:has_html, Html)
	;	true).

format_exception_into_alert_string(E, Str, Html) :-
	(	E = with_processing_context(C,E1)
	->	Context_str = C
	;	(
			Context_str = '',
			E1 = E
		)
	),

	(	E1 = with_backtrace_str(E2, Bstr0)
	->	atomic_list_concat(['prolog stack:\n', Bstr0], Bstr)
	;	(
			E2 = E1,
			Bstr = ''
		)
	),

	(	(
			E2 = error(X, _),
			X \= msg(_)
		)
	->	message_to_string(E2, Msg0)
	;	(	E2 = error(Msg0,Stacktrace)
		->	(	nonvar(Stacktrace)
			->	%stt(Stacktrace, Stacktrace_str)
				format(string(Stacktrace_str),'~q',[Stacktrace])
			;	Stacktrace_str = '')
		;	(
				Stacktrace_str = '',
				Msg0 = E2
			)
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
	format(string(Str ),'~w~n~n~w~n~n~w~q~n',[Context_str, $>stringize(Msg), Bstr, Stacktrace_str]).


make_context_trace_report :-
	get_context_trace(Trace0),
	reverse(Trace0,Trace),
	maplist(make_context_trace_report2,Trace, Html),
	add_report_page_with_body(10, context_trace, [h3([context_trace, ':']), div([class=context_trace], $>flatten(Html))], loc(file_name,'context_trace.html'), context_trace_html).

make_context_trace_report2((Depth, C),div(["-",Stars,Text])) :-
	% or is that supposed to be atom? i forgot again.
	get_indentation(Depth, '* ', Stars),
	context_string2('', C, Text).


'make task_directory report entry' :-
	report_file_path__singleton(loc(file_name, ''), Tmp_Dir_Url, _),
	add_report_file(-100,'task_directory', 'task_directory', Tmp_Dir_Url).


make_doc_dump_report :-
	save_doc(final).

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

	(
		(
			Key == "response.n3",
			\+doc($>result, l:type, l:ledger)
		)
	->	(
			% inline response.n3 into the result json
			tmp_file_path_from_something(loc(_,Url), loc(absolute_path,P)),
			read_file_to_string(P, Contents, []),
			Json = Json0.put(contents,Contents)
		)
	;	Json = Json0 % just url's for all the rest
	).

collect_alerts(Alerts_text, Alerts_html) :-
	findall(
		Alert_text,
		(
			/* every alert is converted into a string, which is put into result json. This isnt currently being displayed to users - they see the html versions collected below. We might probably replace this with a link to the html report, just for easy navigation from command line during development. */
			get_alert(Key,Msg0,_),
			!alert_to_string(Key, Msg0, Alert_text)
		),
		Alerts_text
	),
	findall(
		Alert_html,
		(
			get_alert(Key,Msg0,Uri),
			/* alerts generated from exceptions caught by handle_processing_exception already have html generated from the exception, including stack trace and context trace. todo refactor. Context trace etc extracted from exception should be set on the generated alert, then used here. */
			(	doc(Uri,l:has_html,Alert_html)
			->	true
			;	!alert_to_html(Key, Msg0, Uri, Alert_html))
		),
		Alerts_html
	).

 alert_to_string(Key, Msg0, Alert) :-
	(Msg0 = error(msg(Msg),_) -> true ; Msg0 = Msg),
	(atomic(Msg) -> Msg2 = Msg ; term_string(Msg, Msg2)),
	atomic_list_concat([Key,': ',Msg2], Alert).

 alert_to_html(Key, E1, Uri, Alert_html) :-
	(	E1 = with_backtrace_str(Msg0, Bstr0)
	->	%atomic_list_concat(['prolog stack:\n', Bstr0], Bstr)
		Bstr = details([summary(['prolog stack:']), Bstr0])
	;	(
			Msg0 = E1,
			Bstr = ''
		)
	),

	(	Msg0 = error(msg(Msg),Bt)
	->	(	nonvar(Bt) -> true ; Bt = '')
	;	(
			Msg0 = Msg,
			Bt = ''
		)
	),

	(	Msg = html(Msg2)
	->	true
	;	(	atomic(Msg)
		->	Msg2 = Msg
		;	term_string(Msg, Msg2))
	),

	(	?doc(Uri, l:has_html_message, Html_message)
	->	true
	;	Html_message = ''),

	(	?doc(Uri, l:ctx_str, Ctx_str)
	->	true
	;	Ctx_str = ''),

	Alert_html = p([h4([$>atom_string(<$, $>term_string(Key)),': ']),pre([Msg2]),br([]),Html_message,br([]),pre([Ctx_str]),br([]),pre([Bt]),pre([small([Bstr])])]).


make_alerts_report(Alerts_Html) :-
	(	Alerts_Html = []
	->	Alerts_Html2 = ["no alerts."]
	;	Alerts_Html2 = Alerts_Html),
	add_report_page_with_body(10,alerts, $>flatten([h3([alerts, ':']), Alerts_Html2]), loc(file_name,'alerts.html'), alerts_html).


process_multifile_request(Request_data_uri_base,File_Paths) :-
	debug(tmp_files, "process_multifile_request(~w)~n", [File_Paths]),
	(	accept_request_file(File_Paths, Xml_Tmp_File_Path, xml)
	->	!load_request_xml(Xml_Tmp_File_Path, Dom)
	;	true),

	(	accept_request_file(File_Paths, Rdf_Tmp_File_Path, n3)
	->	(
			!debug(tmp_files, "done:accept_request_file(~w, ~w, n3)~n", [File_Paths, Rdf_Tmp_File_Path]),
			!cf(load_request_rdf(Rdf_Tmp_File_Path, G)),
			!debug(tmp_files, "RDF graph: ~w~n", [G]),
			!cf(doc_from_rdf(G, 'https://rdf.lodgeit.net.au/v1/excel_request#', Request_data_uri_base)),
			!check_request_version
			%doc_input_to_chr_constraints
		)
	;	true),
	(	process_rdf_request
	;	(
			(
				ground(Dom),
				xpath(Dom, //reports, _)
			)
		->	!process_xml_request(Xml_Tmp_File_Path, Dom)
		)
	).
/*
				;	throw_string('<reports> tag not found'))
			;		throw_string('rdf request processing failed'))
*/

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
	tmp_file_path_to_url__singleton(Path, Url),
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
		process_request_depreciation_new;
		process_request_ledger
	),
	ct('process_rdf_request is finished.'),
	cf(make_rdf_response_report).



process_xml_request(File_Path, Dom) :-
/*+   request_xml_to_doc(Dom),*/
	(process_request_car(File_Path, Dom);
	(process_request_loan(File_Path, Dom);
	(process_request_livestock(File_Path, Dom);
	%(process_request_investment:process(File_Path, Dom);
	false
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
