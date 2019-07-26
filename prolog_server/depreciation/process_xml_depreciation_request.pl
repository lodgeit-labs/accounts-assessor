% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_depreciation_request.pl
% Date:      2019-07-26
% ===================================================================

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- module(process_xml_depreciation_request, [process_xml_depreciation_request/2]).

:- use_module(library(xpath)).
:- use_module('../../lib/utils', [inner_xml/3, write_tag/2, fields/2]).
:- use_module('../../lib/days', [parse_date/2]).
:- use_module('../../lib/depreciation_computation', [
		written_down_value/5, 
		depreciation_between_two_dates/6]).


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
	process_basic_values(DOM, Type, Invest_In_Date_In, Request_Date_In, Method, Cost_Unit, Cost_Value_In),	
	
	xpath(DOM, //reports/depreciation_request_written_down_value/rates, Depreciation_Rates_DOM),	
	findall(depreciation_rate(Asset, Year, Value), 
				(
					process_depreciation_rate(Depreciation_Rates_DOM, Asset, Year_In, Value_In),
					atom_number(Year_In, Year),
					atom_number(Value_In, Value)
				), 
				Depreciation_Rates),
	
	writeln('<!--'),
	parse_date(Invest_In_Date_In, Invest_In_Date),
	parse_date(Request_Date_In, Request_Date),
	atom_number(Cost_Value_In, Cost_Value),
	% fixme: description and account values are given here. finally we have to extract these values and update it
	Transaction = transaction(Invest_In_Date, 'TestDescription', motor_vehicles, t_term(Cost_Value, _)),	
	depreciation_between_two_dates(Transaction, Invest_In_Date, Request_Date, Method, Depreciation_Rates, Depreciation_Value),
	% written_down_value(Transaction, Request_Date, Method, Depreciation_Rates, Written_Down_Value),	
	writeln('-->'),
	
	write_tag('type', Type),	
	writeln('<cost>'),
	write_tag('unit', Cost_Unit),
	write_tag('value', Cost_Value),
	writeln('</cost>'),	
	write_tag('invest_in_date', Invest_In_Date_In),
	write_tag('request_date', Request_Date_In),	
	writeln('<written_down_value>'),
	write_tag('unit', Cost_Unit),
	write_tag('value', Depreciation_Value),
	writeln('</written_down_value>').


process_basic_values(DOM, Type, Invest_In_Date, Request_Date, Method, Cost_Unit, Cost_Value) :-
	xpath(DOM, //reports/depreciation_request_written_down_value, Depreciation_Request_Values),
	fields(Depreciation_Request_Values, [
		type, Type,		
		invest_in_date, Invest_In_Date,
		request_date, Request_Date,
		method, Method
	]),	
	
	xpath(DOM, //reports/depreciation_request_written_down_value/cost, Depreciation_Request_Cost_Values),
	fields(Depreciation_Request_Cost_Values, [
		unit, Cost_Unit,		
		value, Cost_Value
	]).


process_depreciation_rate(Depreciation_Rates_DOM, Asset, Year, Value) :-
	xpath(Depreciation_Rates_DOM, //depreciation_rate, Depreciation_Rate),		
	fields(Depreciation_Rate, [
		asset, Asset,
		year, Year,
		value, Value
	]).


