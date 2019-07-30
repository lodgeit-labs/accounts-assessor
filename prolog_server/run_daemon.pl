:- [prolog_server].

% -------------------------------------------------------------------
% Start up Prolog server
% -------------------------------------------------------------------
:- set_flag(prepare_unique_taxonomy_url, true).
:- initialization(run_daemon).
