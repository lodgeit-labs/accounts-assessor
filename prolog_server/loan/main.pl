%--------------------------------------------------------------------
% Load files --- needs to be turned into modules
%--------------------------------------------------------------------

% The program entry point. Run the program using swipl -s main.pl .

% Loads up calendar related predicates
:- ['../../src/days.pl'].
% Loads up predicates pertaining to hire purchase arrangements
:- ['../../src/hirepurchase.pl'].
% Loads up predicates pertaining to loan arrangements
:- ['../../src/loans.pl'].
% Loads up predicates pertaining to bank statements
:- ['../../src/statements.pl'].

:- ['helper'].

:- ['./../prolog_server.pl'].

:- ['./process_xml_request.pl'].


:- initialization(run_server).
