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
:- use_module(loan/process_xml_loan_request, [process_xml_loan_request/2]).
:- use_module(ledger/process_xml_ledger_request, [process_xml_ledger_request/2]).
:- use_module(livestock/process_xml_livestock_request, [process_xml_livestock_request/2]).
/*:- use_module('../lib/utils', [throw_string/1]).*/


% -------------------------------------------------------------------
% process_data/2
% -------------------------------------------------------------------

process_data(FileName, Path) :-
   load_xml(Path, DOM, []),
   process_xml_request(FileName, DOM).
   % format('Content-type: text/plain~n~n'),
   % writeq(DOM),
   % write(FileName),
   % write(Path).

   
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
   (process_xml_livestock_request(FileName, DOM) -> true))).


% -------------------------------------------------------------------
% store_xml_document/2
% -------------------------------------------------------------------

store_xml_document(FileName, XML) :-
   open(FileName, write, Stream),
   write(Stream, XML),
   close(Stream).