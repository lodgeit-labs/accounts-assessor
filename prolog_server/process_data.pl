% ===================================================================
% Project:   LodgeIT
% Module:    main.pl
% Author:    Abdus Salam and Rolf Schwitter
% Date:      2019-05-06
% ===================================================================

% :- style_check([-discontiguous, -singleton]).

% :- module('main.pl', [process_data/1]).

:- use_module(library(xpath)).

% :- ['process_xml_request.pl'].


% -------------------------------------------------------------------
% process_data/1
% -------------------------------------------------------------------

process_data(Data) :-
   parse_data(Data, FileName, XML),
   store_xml_document(FileName, XML), true.
%   process_xml_document(FileName).


% -------------------------------------------------------------------
% parse_data/3
% -------------------------------------------------------------------

parse_data(Data, FileName, XML) :-
   split_header_body(Data, Header, Body), 
   extract_file_name(Header, FileName),true.
%   extract_xml_data(Body, XML).
% spy(parse_data/3).


split_header_body(Data, Header, Body) :-
   string_chars(Data, Chars),
   append(Header, ['<', '?', x, m, l|Rest], Chars),
   Body = ['<', '?', x, m, l|Rest].

extract_file_name(Header, FileName) :-
   append(_, [f, i, l, e, n, a, m, e, '=', '"'|Rest1], Header),   
   append(Name, ['.', x, m, l, '"'|Rest2], Rest1),
   % exclude file location from the filename 
   % (for Internet Explorer/Microsoft Edge)
   (   
     memberchk('\\', Name)
     ->  
     reverse(Name, RName),
     append(RFName, ['\\'|R1], RName),
     reverse(RFName, FName)
   ;   
     FName = Name
   ),
   append(FName, ['.', x, m, l], FileNameChars),
   atomic_list_concat(FileNameChars, FileName).

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

