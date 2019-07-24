% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_depreciation_request.pl
% Date:      2019-07-24
% ===================================================================

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- module(process_xml_depreciation_request, [process_xml_depreciation_request/2]).

:- use_module(library(xpath)).
:- use_module('../../lib/utils', [inner_xml/3, write_tag/2]).


% -------------------------------------------------------------------
% process_xml_depreciation_request/2
% -------------------------------------------------------------------

process_xml_depreciation_request(_, DOM) :-
	writeln('<?xml version="1.0"?>'),
	writeln('<response>'),
	writeln('<depreciation_response_written_down_value>'),

	process(DOM),

	writeln('</depreciation_response_written_down_value>'),
	writeln('</response>'),
	nl, nl.


process(DOM) :-
	inner_xml(DOM, //depreciation_request_written_down_value/type, [Type]),
	inner_xml(DOM, //depreciation_request_written_down_value/cost/unit, [CostUnit]),
	inner_xml(DOM, //depreciation_request_written_down_value/cost/value, [CostValue]),
	inner_xml(DOM, //depreciation_request_written_down_value/invest_in_date, [InvestInDate]),
	inner_xml(DOM, //depreciation_request_written_down_value/request_date, [RequestDate]),
	
	write_tag('type', Type),	
	writeln('<cost>'),
	write_tag('unit', CostUnit),
	write_tag('value', CostValue),
	writeln('</cost>'),	
	
	write_tag('invest_in_date', InvestInDate),
	write_tag('request_date', RequestDate),
	
	writeln('<written_down_value>'),
	write_tag('unit', CostUnit),
	% fixme: need to compute the value using the depreciation calculator
	DepreciationValue = 123,
	write_tag('value', DepreciationValue),
	writeln('</written_down_value>').

   

