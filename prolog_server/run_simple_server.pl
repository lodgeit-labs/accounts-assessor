:- [prolog_server].

:- use_module(library(http/http_error)). 

% -------------------------------------------------------------------
% Start up Prolog server
% -------------------------------------------------------------------

:- initialization(run_simple_server).
