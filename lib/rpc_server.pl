:- use_module(library(http/json)).
:- use_module('residency', []).
:- use_module('sbe', []).
:- use_module(library(prolog_stack)).
:- ['lib'].


:-set_prolog_flag(stack_limit, 10 000 000 000).


process_request_rpc_cmdline :-
	json_read_dict(user_input, Dict),
	process_request_rpc_cmdline1(Dict).

process_request_rpc_cmdline_json_text(String) :-
	string_to_json_dict(String, Dict),
	process_request_rpc_cmdline2(Dict).

:- (getenv('DISPLAY', _) -> guitracer ; true).

process_request_rpc_cmdline1(Dict) :-
	catch_with_backtrace(
		(
			process_request_rpc_cmdline2(Dict)
		),
		E,
		(nl,nl,writeq(E),nl,nl,throw(E))).

process_request_rpc_cmdline2(Dict) :-
	(	Dict.method == "calculator"
	->	process_request_rpc_calculator(Dict.params)
	;	(
		(Dict.method == "sbe"
		->	(
				sbe:sbe_step(Dict.params, Result),
				json_write(current_output, _{result:Result})
			)
		;(Dict.method == "residency"
		->	(
				residency:residency_step(Dict.params, Result),
				json_write(current_output, _{result:Result})
			)
		;json_write(current_output, _{error:_{code:0,message:unknown_method}})))
		)
	).
