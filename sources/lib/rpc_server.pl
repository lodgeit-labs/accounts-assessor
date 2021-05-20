:- use_module(library(http/json)).
:- use_module('residency', []).
:- use_module('sbe', []).
:- use_module(library(prolog_stack)).

:- ['lib'].

:-set_prolog_flag(stack_limit, 46_000_000_000).

:- (have_display -> guitracer ; true).


/* read command from stdin */
process_request_rpc_cmdline :-
	json_read_dict(user_input, Dict),
	process_request_rpc_cmdline1(Dict).

/* or get command as a parameter of goal */
process_request_rpc_cmdline_json_text(String) :-
	string_to_json_dict(String, Dict),
	process_request_rpc_cmdline2(Dict).

/* process request, print error to stdout, reraise */
process_request_rpc_cmdline1(Dict) :-
	catch_with_backtrace(
		(
			process_request_rpc_cmdline2(Dict)
		),
		E,
		(nl,nl,writeq(E),nl,nl,throw(E))
	).



process_request_rpc_cmdline2(Dict) :-
	process_request_rpc_cmdline3(Dict.method, Dict),
	flush_output.



process_request_rpc_cmdline3("calculator", Dict) :-
	!,
	!process_request_rpc_calculator(Dict.params).

process_request_rpc_cmdline3("chat", Dict) :-
	!,
	!do_chat(Dict, Response),
	json_write(current_output, Response).

process_request_rpc_cmdline3(_,_) :-
	json_write(current_output, err{error:m{message:unknown_method}}).




do_chat(Dict, Response) :-
	Type = Dict.params.get(type),
	do_chat2(Type, Dict, Response).

do_chat2("sbe", Dict, r{result:Result}) :-
	sbe:sbe_step(Dict.params, Result).

do_chat2("residency", Dict, r{result:Result}) :-
	residency:residency_step(Dict.params, Result).

