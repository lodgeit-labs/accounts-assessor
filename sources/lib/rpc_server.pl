:- if(\+getenv('SWIPL_NODEBUG', true)).
	:- format(user_error, 'SWIPL_NODEBUG off~n', []).
	:- debug.
:- else.
	:- format(user_error, 'SWIPL_NODEBUG on~n', []).
:- endif.

:- use_module(library(http/json)).
:- use_module('residency', []).
:- use_module('sbe', []).
:- use_module(library(prolog_stack)).

:- ['lib'].

%:-set_prolog_flag(compile_meta_arguments, always).
%:-set_prolog_flag(stack_limit, 9080706050403020100).
%hhh :- current_prolog_flag(malloc,X),format(user_error, '~q~n', [X]).
%:- hhh.
%:- set_prolog_stack(global, spare(20000)).
%:- set_prolog_stack(local, spare(20000)).
%:- set_prolog_stack(trail, spare(20000)).


%:- ((have_display,flag(gtrace,true)) -> (writeq(wtf),nl,nl,halt(0),guitracer) ; true). % this would precede evaluation the flag setting goal passed to swipl on command line

%:- print_debugging_checklist.

:- misc_check(env_bool('PYTHONUNBUFFERED', true)).





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
	%profile(
	process_request_rpc_cmdline3(Dict.method, Dict.params),
	%[]),gtrace,
	flush_output.


/*process_request_rpc_cmdline3("testcase_permutations", Params) :-
	findall(Testcase,
		(

			testcase(T),
			include(ground, T, T2),
			dict_pairs(Params, _, Params_pairs),
			append(Params_pairs, T2, T3),
			maplist(pair_to_json, T3, Testcase)
		),
		Testcases
	),
	json_write(current_output, response{status:ok, result: Testcases}).*/

process_request_rpc_cmdline3("calculator", Dict) :-
	!,
	!process_request_rpc_calculator(Dict).

process_request_rpc_cmdline3("chat", Dict) :-
	!,
	!(do_chat(Dict, Response)),
	json_write(current_output, Response).

process_request_rpc_cmdline3(_,_) :-
	json_write(current_output, response{status:error, message:unknown_method}).




do_chat(Dict, Response) :-
	Type = Dict.get(type),
	do_chat2(Type, Dict, Response).

do_chat2("sbe", Dict, r{result:Result}) :-
	sbe:sbe_step(Dict, Result).

do_chat2("residency", Dict, r{result:Result}) :-
	residency:residency_step(Dict, Result).

