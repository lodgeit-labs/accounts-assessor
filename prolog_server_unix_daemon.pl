% ===================================================================
% Project:   LodgeiT
% Module:    Prolog Server for Unix
% Author:    Abdus Salam and Rolf Schwitter
% Date:      2019-06-02
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
:- use_module(library(http/http_error)).
:- use_module(library(http/http_header)).
:- use_module(library(http/http_multipart_plugin)).
:- use_module(library(http/http_client)).
:- use_module(library(http/html_write)).
:- use_module(library(http/http_unix_daemon)).

:- ensure_loaded('process_data.pl').


% -------------------------------------------------------------------
% http_handler/3
% -------------------------------------------------------------------

:- http_handler(root(.),	upload_form, []).
:- http_handler(root(upload),	upload,      []).


% -------------------------------------------------------------------
% run_server/0
% -------------------------------------------------------------------

run_server :-   
   http_daemon([port(8080)]).


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
   http_read_data(Request, Data, [to(string)]),
   process_data(Data).
  

upload(_Request) :-
   throw(http_reply(bad_request(bad_file_upload))).


% -------------------------------------------------------------------
% multipart_post_request/1
% -------------------------------------------------------------------

multipart_post_request(Request) :-
   memberchk(method(post), Request),
   memberchk(content_type(ContentType), Request),
   http_parse_header_value(content_type, ContentType, media(multipart/'form-data', _)).

   
:- multifile prolog:message//1.

prolog:message(bad_file_upload) -->
   [ 'A file upload must be submitted as multipart/form-data using', nl,
     'name=file and providing a file-name'
   ].


% -------------------------------------------------------------------
% start up Prolog server
% -------------------------------------------------------------------

:- initialization(run_server).
