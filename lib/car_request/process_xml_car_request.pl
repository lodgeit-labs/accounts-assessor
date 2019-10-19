% ===================================================================
% Project:   LodgeiT
% File:      process_xml_car_request.pl
% Author:    
% Date:      2019-08-01
% ===================================================================

% -------------------------------------------------------------------
% Modules
% -------------------------------------------------------------------

:- module(process_xml_car_request, 
		[process_xml_car_request/2]).

:- use_module(library(xpath)).
:- use_module(library(http/json)).
:- use_module(library(http/http_open)).

:- use_module('../files', [
		absolute_tmp_path/2
]).
:- use_module('../xml', [
		validate_xml/2
]).

:- dynamic(known_ner_response/2).


ner_api_url("http://13.239.25.136:8012/NER/").

query_ner_api(Request_Text, Response_JSON) :-
	uri_encoded(query_value,Request_Text,Request_Text_Encoded),
	ner_api_url(API_URL),
	atomic_list_concat([API_URL,Request_Text_Encoded],'',Request_URI),
	setup_call_cleanup(
        http_open(Request_URI, In, [request_header('Accept'='application/json')]),
        json_read_dict(In, Response_JSON),
        close(In)
    ).

json_contains_value(Response_JSON,Value) :-
	Value = Response_JSON.get(_).


check_ner_api_results(Response_JSON) :-
	json_contains_value(Response_JSON,"B-CMK"),
	json_contains_value(Response_JSON,"B-CMD").
	

cached_ner_data(Request_Text, Response_JSON) :-
    known_ner_response(Request_Text, Response_JSON) ;
    query_ner_api(Request_Text, Response_JSON),
    assert(known_ner_response(Request_Text, Response_JSON)).

process_ner_api_results(Response_JSON,Result_XML) :-
	(
		check_ner_api_results(Response_JSON) 
	-> 	
		Result = "Yes" 
	; 
		Result = "No"
	),
	Result_XML = element(reports,[],[element(is_car_response,[],[Result])]).

process_xml_car_request(File_Name,DOM) :-
	xpath(DOM, //reports/car_request, element(_,_,[Request_Text])),

	/*
	absolute_tmp_path(File_Name, Instance_File),
	catch(
		setup_call_cleanup(
			process_create('../python/venv/bin/python3',['../python/src/xmlschema_runner.py',Instance_File,'schemas/bases/Reports.xsd'],[]),
			true,
			true
		),
		_,
		throw('Input file failed XSD schema validation.')
	),
	*/

	absolute_tmp_path(File_Name, Instance_File),
	validate_xml(Instance_File, 'schemas/bases/Reports.xsd'),

	cached_ner_data(Request_Text,Response_JSON),
	process_ner_api_results(Response_JSON,Result_XML),
	xml_write(Result_XML,[]).
