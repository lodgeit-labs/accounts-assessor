% ===================================================================
% Project:   LodgeiT
% File:      process_data.pl
% Author:    Abdus Salam and Rolf Schwitter
% Date:      2019-06-02
% ===================================================================

% -------------------------------------------------------------------
% Modules
% -------------------------------------------------------------------

:- use_module(library(xpath)).
:- use_module(library(http/http_dispatch), [http_safe_file/2]).
:- use_module(loan/process_xml_loan_request, [process_xml_loan_request/2]).
:- use_module(ledger/process_xml_ledger_request, [process_xml_ledger_request/2]).   	  


% -------------------------------------------------------------------
% process_data/1
% -------------------------------------------------------------------

process_data(Data) :-
   parse_data(Data, FileName, XML),
   store_xml_document(FileName, XML),
   process_xml_document(FileName),
   delete_file(FileName).


% -------------------------------------------------------------------
% parse_data/3
% -------------------------------------------------------------------

parse_data(Data, FileName, XML) :-
   split_header_body(Data, Header, Body), 
   extract_file_name(Header, FileName),
   extract_xml_data(Body, XML).

split_header_body(Data, Header, Body) :-
   string_chars(Data, Chars),
   append(Header, ['<', '?', x, m, l|Rest], Chars),
   Body = ['<', '?', x, m, l|Rest].

extract_file_name(Header, FileName2) :-
   append(_, [f, i, l, e, n, a, m, e, '=', '"'|Rest1], Header),   
   append(Name, ['.', x, m, l, '"'|Rest2], Rest1),
   exclude_file_location_from_filename(Name, FName),
   append(FName, ['.', x, m, l], FileNameChars),
   atomic_list_concat(FileNameChars, FileName),
   http_safe_file(FileName, []),
   atomic_list_concat(["tmp/", FileName], FileName2).

exclude_file_location_from_filename(Name, FName) :-
   % (for Internet Explorer/Microsoft Edge)
   once((
   memberchk('\\', Name)
   ->  
     reverse(Name, RName),
     append(RFName, ['\\'|R1], RName),
     reverse(RFName, FName)
   ;   
     FName = Name)).


extract_xml_data(Body, XMLString) :-
      reverse(Body, RBody),
      append(_, ['>'|Rest], RBody),
      reverse(['>'|Rest], XMLChars),
      string_chars(XMLString, XMLChars).


% -------------------------------------------------------------------
% store_xml_document/2
% -------------------------------------------------------------------

store_xml_document(FileName, XML) :-
   open(FileName, write, Stream),
   write(Stream, XML),
   close(Stream).


% -------------------------------------------------------------------
% process_xml_document/1
% -------------------------------------------------------------------

process_xml_document(FileName) :-
   load_xml(FileName, DOM, []),
   process_xml_request(FileName, DOM).

   
% -------------------------------------------------------------------
% process_xml_request/2
% -------------------------------------------------------------------

process_xml_request(FileName, DOM) :-
   (
      process_xml_loan_request(FileName, DOM)
   ;
      process_xml_ledger_request(FileName, DOM)
   ).
     

