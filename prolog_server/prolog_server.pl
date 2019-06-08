% ===================================================================
% Project:   LodgeiT
% Module:    Prolog Server
% Author:    Schwitter
% Date:      2019-06-08
% ===================================================================

% -------------------------------------------------------------------
% Style checking
% -------------------------------------------------------------------

:- style_check([-discontiguous, -singleton]).

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

:- ensure_loaded('process_data.pl').


% -------------------------------------------------------------------
% Handler
% -------------------------------------------------------------------

:- http_handler(root(.),      upload_form, []).
:- http_handler(root(upload), upload,      []).


% -------------------------------------------------------------------
% run_server/0
% -------------------------------------------------------------------

run_server :-
   Port = port(8080),
   (
      getenv(os, OSName),
      OSName = 'Windows_NT'
      -> 
      http_server(http_dispatch, [Port])
   ;
      use_module(library(http/http_unix_daemon)),
      http_daemon([Port])
   ).

   
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
   http_read_data(Request, Parts, [ on_filename(save_file) ]),
   memberchk(file=file(FileName, Path), Parts),
   process_data(FileName, Path),
   delete_file(Path).

	
upload(_Request) :-
   throw(http_reply(bad_request(bad_file_upload))).


% -------------------------------------------------------------------
% multipart_post_request/1
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
   atomic_list_concat(['./tmp/', FileName], Path),
   setup_call_cleanup(open(Path, write, Out), copy_stream_data(In, Out), close(Out)).


% -------------------------------------------------------------------
% message/1
% -------------------------------------------------------------------

:- multifile prolog:message//1.

prolog:message(bad_file_upload) -->
   [ 'A file upload must be submitted as multipart/form-data using', nl,
      'name=file and providing a file-name' ].

% -------------------------------------------------------------------
% Start up Prolog server
% -------------------------------------------------------------------

:- initialization(run_server).
