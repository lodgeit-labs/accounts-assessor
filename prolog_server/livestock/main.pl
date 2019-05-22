%--------------------------------------------------------------------
% Load files --- needs to be turned into modules
%--------------------------------------------------------------------

:- debug.

:- ['./../../src/days.pl'].
:- ['./../prolog_server.pl'].
:- ['./process_xml_request.pl'].

:- initialization(run_server).
