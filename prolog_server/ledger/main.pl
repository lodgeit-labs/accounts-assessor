%--------------------------------------------------------------------
% Load files --- needs to be turned into modules
%--------------------------------------------------------------------

:- debug.

:- ['./../../src/days.pl'].
:- ['./../../src/ledger.pl'].
:- ['./../../src/statements.pl'].
:- ['./../prolog_server.pl'].
:- ['./process_xml_request.pl'].

:- run_server.
:- process_xml_document("ledger-request.xml").
:- halt.