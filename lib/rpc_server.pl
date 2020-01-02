:- use_module(library(http/json)).
:- use_module('residency', []).
:- use_module('sbe', []).
:- use_module('lib', []).

process_request_rpc_cmdline :-
	json_read_dict(user_input, Dict),
	(	Dict.method == "calculator"
	->	lib:process_request_rpc_calculator(Dict.params)
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
