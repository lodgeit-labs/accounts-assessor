% ===================================================================
% Project:   LodgeiT
% File:      process_data.pl
% Author:    Rolf Schwitter
% Date:      2019-06-08
% ===================================================================

% -------------------------------------------------------------------
% Modules
% -------------------------------------------------------------------

:- use_module(library(xpath)).
:- use_module('../lib/files', []).
:- use_module(loan/process_xml_loan_request, [process_xml_loan_request/2]).
:- use_module(ledger/process_xml_ledger_request, [process_xml_ledger_request/2]).
:- use_module(livestock/process_xml_livestock_request, [process_xml_livestock_request/2]).
:- use_module(investment/process_xml_investment_request, [process_xml_investment_request/2]).
/*:- use_module('../lib/utils', [throw_string/1]).*/



/*
run a test case if url is /tests/xxx!
*/
tests(Url, _) :-
	sub_string(Url,_,_,0,"r"),
	sub_string(Url,0,_,1,Relative_Path),
	absolute_file_name(my_tests(Relative_Path), Path, [ access(read) ]),
	process_data(_FileName, Path).

/*
just display a test file if the url is /tests/xxx
*/
tests(Test, _) :-
	http_reply_file(my_tests(Test),[],[]).

% -------------------------------------------------------------------
% process_data/2
% -------------------------------------------------------------------

process_data(FileName, Path) :-
   format('Content-type: text/xml~n~n'),
   process_data2(FileName, Path).
   % writeq(DOM),
   % write(FileName),
   % write(Path).

process_data2(FileName, Path) :-
   load_xml(Path, DOM, []),
   process_xml_request(FileName, DOM).

   
% -------------------------------------------------------------------
% process_xml_request/2
% -------------------------------------------------------------------

process_xml_request(FileName, DOM) :-
   (
      xpath(DOM, //reports, _)
   ->
      true
   ;
      throw('<reports> tag no found')
   ),
   (process_xml_loan_request(FileName, DOM) -> true;
   (process_xml_ledger_request(FileName, DOM) -> true;
   (process_xml_livestock_request(FileName, DOM) -> true;
   (process_xml_investment_request(FileName, DOM) -> true)))).


% -------------------------------------------------------------------
% store_xml_document/2
% -------------------------------------------------------------------

store_xml_document(FileName, XML) :-
   open(FileName, write, Stream),
   write(Stream, XML),
   close(Stream).
