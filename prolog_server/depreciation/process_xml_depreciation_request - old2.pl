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
	(
		xpath(DOM, //depreciation_request_written_down_value, _)
	->
		process_written_down_value(DOM)
	;
		process_depreciation_between_two_dates(DOM)
	).	


process_written_down_value(DOM) :-
	/* xpath(DOM, //reports/depreciation_request_written_down_value, Depreciation_Request_Values),
	process_basic_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, Method, Cost_Unit, Cost_Value_In),	
	
	xpath(DOM, //reports/depreciation_request_written_down_value/rates, Depreciation_Rates_DOM),	
	findall(depreciation_rate(Asset, Year, Value), 
				(
					process_depreciation_rate(Depreciation_Rates_DOM, Asset, Year_In, Value_In),
					(nonvar(Year_In) -> atom_number(Year_In, Year)),
					% atom_number(Year_In, Year),
					atom_number(Value_In, Value)
				), 
				Depreciation_Rates), */
	
	xpath(DOM, //reports/depreciation_request_written_down_value, Depreciation_Request_Values),
	process_initial_common_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, 
		Method, Cost_Unit, Cost_Value_In, Depreciation_Rates),
	
	writeln('<?xml version="1.0"?>'),
	writeln('<!--'),
	parse_date(Invest_In_Date_In, Invest_In_Date),
	parse_date(Request_Date_In, Request_Date),
	atom_number(Cost_Value_In, Cost_Value),
	% fixme: account value is given here. finally we have to extract this value and update it
	Transaction = transaction(Invest_In_Date, '', motor_vehicles, t_term(Cost_Value, _)),	
	% depreciation_between_two_dates(Transaction, Invest_In_Date, Request_Date, Method, Depreciation_Rates, Depreciation_Value),
	written_down_value(Transaction, Request_Date, Method, Depreciation_Rates, Written_Down_Value),	
	writeln('-->'),
	
	
	write_depreciation_response(written_down_value, 
		Type, Cost_Unit, Cost_Value, Invest_In_Date_In, Request_Date_In, Cost_Unit, Written_Down_Value).
	/*
	writeln('<response>'),
	writeln('<depreciation_response_written_down_value>'),
	write_tag('type', Type),	
	writeln('<cost>'),
	write_tag('unit', Cost_Unit),
	write_tag('value', Cost_Value),
	writeln('</cost>'),	
	write_tag('invest_in_date', Invest_In_Date_In),
	write_tag('request_date', Request_Date_In),	
	writeln('<written_down_value>'),
	write_tag('unit', Cost_Unit),
	write_tag('value', Written_Down_Value),
	writeln('</written_down_value>'),
	writeln('</depreciation_response_written_down_value>'),
	writeln('</response>'),
	nl, nl.*/


process_depreciation_between_two_dates(DOM) :-
	/* xpath(DOM, //reports/depreciation_request_depreciation_between_two_dates, Depreciation_Request_Values),
	process_basic_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, Method, Cost_Unit, Cost_Value_In),
	
	xpath(DOM, //reports/depreciation_request_depreciation_between_two_dates/rates, Depreciation_Rates_DOM),	
	findall(depreciation_rate(Asset, Year, Value), 
				(
					process_depreciation_rate(Depreciation_Rates_DOM, Asset, Year_In, Value_In),
					(nonvar(Year_In) -> atom_number(Year_In, Year)),
					% atom_number(Year_In, Year),
					atom_number(Value_In, Value)
				), 
				Depreciation_Rates), */
	
	xpath(DOM, //reports/depreciation_request_depreciation_between_two_dates, Depreciation_Request_Values),
	process_initial_common_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, 
		Method, Cost_Unit, Cost_Value_In, Depreciation_Rates),
	
	writeln('<?xml version="1.0"?>'),
	writeln('<!--'),
	parse_date(Invest_In_Date_In, Invest_In_Date),
	parse_date(Request_Date_In, Request_Date),
	atom_number(Cost_Value_In, Cost_Value),
	% fixme: account value is given here. finally we have to extract this value and update it
	Transaction = transaction(Invest_In_Date, '', motor_vehicles, t_term(Cost_Value, _)),	
	depreciation_between_two_dates(Transaction, Invest_In_Date, Request_Date, Method, Depreciation_Rates, Depreciation_Value),
	% written_down_value(Transaction, Request_Date, Method, Depreciation_Rates, Written_Down_Value),	
	writeln('-->'),
	
	write_depreciation_response(depreciation_between_two_dates, 
		Type, Cost_Unit, Cost_Value, Invest_In_Date_In, Request_Date_In, Cost_Unit, Depreciation_Value).
	/*
	writeln('<response>'),
	writeln('<depreciation_response_depreciation_between_two_dates>'),
	write_tag('type', Type),	
	writeln('<cost>'),
	write_tag('unit', Cost_Unit),
	write_tag('value', Cost_Value),
	writeln('</cost>'),	
	write_tag('invest_in_date', Invest_In_Date_In),
	write_tag('request_date', Request_Date_In),	
	writeln('<depreciation_between_two_dates>'),
	write_tag('unit', Cost_Unit),
	write_tag('value', Depreciation_Value),
	writeln('</depreciation_between_two_dates>'),
	writeln('</depreciation_response_depreciation_between_two_dates>'),
	writeln('</response>'),
	nl, nl.*/


process_initial_common_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, 
								Method, Cost_Unit, Cost_Value_In, Depreciation_Rates) :-
	% xpath(DOM, //reports/depreciation_request_written_down_value, Depreciation_Request_Values),
	process_basic_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, Method, Cost_Unit, Cost_Value_In),	
	
	xpath(Depreciation_Request_Values, //rates, Depreciation_Rates_DOM),	
	findall(depreciation_rate(Asset, Year, Value), 
				(
					process_depreciation_rate(Depreciation_Rates_DOM, Asset, Year_In, Value_In),
					(nonvar(Year_In) -> atom_number(Year_In, Year)),
					% atom_number(Year_In, Year),
					atom_number(Value_In, Value)
				), 
				Depreciation_Rates).


process_basic_values(Depreciation_Request_Values, Type, Invest_In_Date, Request_Date, Method, Cost_Unit, Cost_Value) :-
	% xpath(DOM, //reports/depreciation_request_written_down_value, Depreciation_Request_Values),
	fields(Depreciation_Request_Values, [
		type, Type,		
		invest_in_date, Invest_In_Date,
		request_date, Request_Date,
		method, Method
	]),	
	
	xpath(Depreciation_Request_Values, //cost, Depreciation_Request_Cost_Values),
	fields(Depreciation_Request_Cost_Values, [
		unit, Cost_Unit,		
		value, Cost_Value
	]).


process_depreciation_rate(Depreciation_Rates_DOM, Asset, Year, Value) :-
	xpath(Depreciation_Rates_DOM, //depreciation_rate, Depreciation_Rate),
	inner_xml(Depreciation_Rate, //asset, [Asset]),
	(inner_xml(Depreciation_Rate, //year, [Year]) -> true ; true),
	inner_xml(Depreciation_Rate, //value, [Value]).
	/* xpath(Depreciation_Rates_DOM, //depreciation_rate, Depreciation_Rate),	
	fields(Depreciation_Rate, [
		asset, Asset,
		year, Year,
		value, Value
	]). */


write_depreciation_response(RequestFor, Type, Cost_Unit, Cost_Value, Invest_In_Date, Request_Date, Cost_Unit, Depreciation_Computed_Value) :-
	writeln('<response>'),
	(
		RequestFor == depreciation_between_two_dates 
	->  
		writeln('<depreciation_response_depreciation_between_two_dates>')
	;
		writeln('<depreciation_response_written_down_value>')
	),
	write_tag('type', Type),	
	writeln('<cost>'),
	write_tag('unit', Cost_Unit),
	write_tag('value', Cost_Value),
	writeln('</cost>'),	
	write_tag('invest_in_date', Invest_In_Date),
	write_tag('request_date', Request_Date),		
	(
		RequestFor == depreciation_between_two_dates 
	->  
		writeln('<depreciation_between_two_dates>')
	;
		writeln('<written_down_value>')
	),
	write_tag('unit', Cost_Unit),
	write_tag('value', Depreciation_Computed_Value),	
	(
		RequestFor == depreciation_between_two_dates 
	->  
		writeln('</depreciation_between_two_dates>'),
		writeln('</depreciation_response_depreciation_between_two_dates>')
	;
		writeln('</written_down_value>'),
		writeln('</depreciation_response_written_down_value>')
	),
	writeln('</response>'),
	nl, nl.


