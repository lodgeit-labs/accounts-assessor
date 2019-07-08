% ===================================================================
% Project:   LodgeiT
% Module:    Prolog Server
% Author:    Schwitter
% Date:      2019-06-08
% ===================================================================

% -------------------------------------------------------------------
% Style checking
% -------------------------------------------------------------------

:- style_check([-discontiguous, +singleton]).

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_header)).
:- use_module(library(http/http_multipart_plugin)).
:- use_module(library(http/http_client)).
:- use_module(library(http/html_write)).
:- use_module(library(option)).
:- use_module(library(http/http_dispatch), [http_safe_file/2]).
:- use_module(library(http/http_files)).

:- use_module('../lib/files').
:- use_module('chat/residency').
:- use_module('chat/sbe').
:- ensure_loaded('process_data.pl').


% -------------------------------------------------------------------
% Handler
% -------------------------------------------------------------------

:- http_handler(root(.),      upload_form, []).
:- http_handler(root(upload), upload,      []).
:- http_handler(root(chat/sbe), sbe_request, [methods([post])]).
:- http_handler(root(chat/residency), residency_request, [methods([post])]).
:- http_handler('/favicon.ico', http_reply_file('static/favicon.ico', []), []).
:- http_handler(root(.), http_reply_from_files('.', []), [prefix]).



% -------------------------------------------------------------------
% run_simple_server/0
% -------------------------------------------------------------------

run_simple_server :-
   Port = port(8080),
   http_server(http_dispatch, [Port]).

% -------------------------------------------------------------------
% run_daemon/0
% -------------------------------------------------------------------

run_daemon :-
   use_module(library(http/http_unix_daemon)),
   http_daemon().
   
% -------------------------------------------------------------------
% upload_form/1
% -------------------------------------------------------------------

upload_form(_Request) :-
   reply_html_page(
            title('LodgeiT Demo'),
	    [ h1('LodgeiT Demo'),
	      form([ method('POST'),
		     action(location_by_id(upload)),
		     enctype('multipart/form-data')
		   ],
		   table([],
			 [ tr([td(input([type(file), name(file)]))]),
			   tr([td(align(left), input([type(submit), value('Upload XML file')]))])
			 ]))
	    ]).


% -------------------------------------------------------------------
% upload/1
% -------------------------------------------------------------------

upload(Request) :-
   multipart_post_request(Request), !,
   /*todo: assert a unique thread-local my_tmp for each request here*/
   http_read_data(Request, Parts, [ on_filename(save_file) ]),
   memberchk(file=file(FileName, Path), Parts),
   catch(
	   process_data(FileName, Path),
	   string(E),
	   throw(http_reply(bad_request(string(E))))
   ).
   %   delete_file(Path). we shouldn't save and load those files once in production, this is just a debugging feature, a not very useful if the files get deleted after the request is done.

	
upload(_Request) :-
   throw(http_reply(bad_request(bad_file_upload))).


% -------------------------------------------------------------------
% multipart_post_request/
% -------------------------------------------------------------------

multipart_post_request(Request) :-
   memberchk(method(post), Request),
   memberchk(content_type(ContentType), Request),
   http_parse_header_value(content_type, ContentType, media(multipart/'form-data', _)).


% -------------------------------------------------------------------
% save_file/3
% -------------------------------------------------------------------

:- public save_file/3.

save_file(In, file(FileName, Path), Options) :-
   option(filename(FileName), Options),
   exclude_file_location_from_filename(FileName, FileName2),
   http_safe_file(FileName2, []),
   absolute_file_name(my_tmp(FileName2), Path, []),
   setup_call_cleanup(open(Path, write, Out), copy_stream_data(In, Out), close(Out)).


exclude_file_location_from_filename(Name_In, Name_Out) :-
   % (for Internet Explorer/Microsoft Edge)
   atom_chars(Name_In, Name1),
   remove_before('\\', Name1, Name2),
   remove_before('/', Name2, Name3),
   atomic_list_concat(Name3, Name_Out).

remove_before(Slash, Name_In, Name_Out) :-
   once((
   memberchk(Slash, Name_In)
   ->  
     reverse(Name_In, RName),
     append(RFName, [Slash|_R1], RName),
     reverse(RFName, Name_Out)
   ;   
     Name_Out = Name_In)
    ).

% -------------------------------------------------------------------
% message/1
% -------------------------------------------------------------------

:- multifile prolog:message//1.

prolog:message(bad_file_upload) -->
   [ 'A file upload must be submitted as multipart/form-data POST request using', nl,
      'name=file and providing a file-name' ].

prolog:message(string(S)) --> [ S ].



