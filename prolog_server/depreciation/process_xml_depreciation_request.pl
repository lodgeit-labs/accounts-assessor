% ===================================================================
% Project:   LodgeiT
% Module:    process_xml_depreciation_request.pl
% Date:      2019-07-30
% ===================================================================

%--------------------------------------------------------------------
% Modules
%--------------------------------------------------------------------

:- module(process_xml_depreciation_request, [process_xml_depreciation_request/2]).

:- use_module(library(xpath)).
:- use_module('../../lib/utils', [inner_xml/3, write_tag/2, fields/2, throw_string/1]).
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
	xpath(DOM, //reports/depreciation_request_written_down_value, Depreciation_Request_Values),
	process_initial_common_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, 
		Method, Cost_Unit, Cost_Value_In, Depreciation_Rates),	
	
	convert_dates_and_values(Invest_In_Date_In, Request_Date_In, Cost_Value_In,	Invest_In_Date, Request_Date, Cost_Value),
	get_account_and_transaction(Depreciation_Request_Values, Type, Depreciation_Rates, Invest_In_Date, Cost_Value, Account, Transaction),	
	findall(depreciation_rate(Account, Value1, Value2), 
			member(depreciation_rate(Account, Value1, Value2), Depreciation_Rates), 
			Filtered_Depreciation_Rates),
	
	writeln('<?xml version="1.0"?>'),
	writeln('<!--'),
	(
		written_down_value(Transaction, Request_Date, Method, Filtered_Depreciation_Rates, Written_Down_Value)
	-> 
		true
	; 
		throw_string('Cannot compute the requested value.')
	),	
	writeln('-->'),	
	
	write_depreciation_response(written_down_value, 
		Type, Cost_Unit, Cost_Value, Invest_In_Date_In, Request_Date_In, Cost_Unit, Written_Down_Value).
	

process_depreciation_between_two_dates(DOM) :-
	xpath(DOM, //reports/depreciation_request_depreciation_between_two_dates, Depreciation_Request_Values),
	process_initial_common_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, 
		Method, Cost_Unit, Cost_Value_In, Depreciation_Rates),	
		
	convert_dates_and_values(Invest_In_Date_In, Request_Date_In, Cost_Value_In,	Invest_In_Date, Request_Date, Cost_Value),
	get_account_and_transaction(Depreciation_Request_Values, Type, Depreciation_Rates, Invest_In_Date, Cost_Value, Account, Transaction),
	findall(depreciation_rate(Account, Value1, Value2), 
			member(depreciation_rate(Account, Value1, Value2), Depreciation_Rates), 
			Filtered_Depreciation_Rates),
	
	writeln('<?xml version="1.0"?>'),
	writeln('<!--'),
	(
		depreciation_between_two_dates(Transaction, Invest_In_Date, Request_Date, Method, Filtered_Depreciation_Rates, Depreciation_Value)
	-> 
		true
	; 
		throw_string('Cannot compute the requested value.')
	),
	writeln('-->'),
	
	write_depreciation_response(depreciation_between_two_dates, 
		Type, Cost_Unit, Cost_Value, Invest_In_Date_In, Request_Date_In, Cost_Unit, Depreciation_Value).

	
process_initial_common_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, 
								Method, Cost_Unit, Cost_Value_In, Depreciation_Rates) :-
	process_basic_values(Depreciation_Request_Values, Type, Invest_In_Date_In, Request_Date_In, Method, Cost_Unit, Cost_Value_In),	
	
	xpath(Depreciation_Request_Values, //rates, Depreciation_Rates_DOM),	
	findall(depreciation_rate(Asset, Year, Value), 
			process_depreciation_rate(Depreciation_Rates_DOM, Asset, Year, Value),
			Depreciation_Rates).


process_basic_values(Depreciation_Request_Values, Type, Invest_In_Date, Request_Date, Method, Cost_Unit, Cost_Value) :-
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
	(
		inner_xml(Depreciation_Rate, //year, [Year_In]) 
	-> 
		atom_number(Year_In, Year) 
	; 
		true
	),
	inner_xml(Depreciation_Rate, //value, [Value_In]),	
	atom_number(Value_In, Value).

	
extract_account(Depreciation_Request_Values, Type, Depreciation_Rates, Account) :-
	xpath(Depreciation_Request_Values, //types, Types_Values),
	findall(types(Name, Parent), 
			process_account_type(Types_Values, Name, Parent),
			Account_Types),	
	
	find_type(Type, Account_Types, Depreciation_Rates, Account).
	

process_account_type(Types_Values, Name, Parent) :-
	xpath(Types_Values, //type, Type),
	inner_xml(Type, //name, [Name]),
	inner_xml(Type, //parent, [Parent]).
	
	
find_type(_, [], _, _). % fixme: need to process if account not found in depreciation rates
find_type(Type, [Account_Type | Account_Type_List], Depreciation_Rates, Account) :-
	Account_Type = types(Type, Type_Parent),
	(
		member(depreciation_rate(Type_Parent, _, _), Depreciation_Rates)
	->
		Account = Type_Parent
	;
		find_type(Type_Parent, Account_Type_List, Depreciation_Rates, Account)
	).
	
	
convert_dates_and_values(Invest_In_Date_In, Request_Date_In, Cost_Value_In,	Invest_In_Date, Request_Date, Cost_Value) :-
	parse_date(Invest_In_Date_In, Invest_In_Date),
	parse_date(Request_Date_In, Request_Date),
	atom_number(Cost_Value_In, Cost_Value).


get_account_and_transaction(Depreciation_Request_Values, Type, Depreciation_Rates, Invest_In_Date, Cost_Value, Account, Transaction) :-
	extract_account(Depreciation_Request_Values, Type, Depreciation_Rates, Account),
	Transaction = transaction(Invest_In_Date, '', Account, t_term(Cost_Value, _)).
	

write_depreciation_response(RequestFor, Type, Cost_Unit, Cost_Value, Invest_In_Date, Request_Date, Cost_Unit, Depreciation_Computed_Value) :-
	writeln('<response>'),
	write_conditional_value(RequestFor, 
		'<depreciation_response_depreciation_between_two_dates>', 
		'<depreciation_response_written_down_value>'),
	write_tag('type', Type),	
	writeln('<cost>'),
	write_tag('unit', Cost_Unit),
	write_tag('value', Cost_Value),
	writeln('</cost>'),	
	write_tag('invest_in_date', Invest_In_Date),
	write_tag('request_date', Request_Date),		
	write_conditional_value(RequestFor, 
		'<depreciation_between_two_dates>', 
		'<written_down_value>'),
	write_tag('unit', Cost_Unit),
	format(string(Computed_Value), '~2f', Depreciation_Computed_Value),
	write_tag('value', Computed_Value),	
	write_conditional_value(RequestFor, 
		'</depreciation_between_two_dates>\n</depreciation_response_depreciation_between_two_dates>', 
		'</written_down_value>\n</depreciation_response_written_down_value>'),
	writeln('</response>'),
	nl, nl.
	

write_conditional_value(RequestFor, BetweenDatesTagValue, WrittenDownTagValue) :-
	(
		RequestFor == depreciation_between_two_dates 
	->  		
		writeln(BetweenDatesTagValue)
	;		
		writeln(WrittenDownTagValue)
	).

