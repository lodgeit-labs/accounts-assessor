:- begin_tests(facts, [setup(mock_request)]).


test(evaluate_fact, all(Out = ['AUD5'])) :-
	make_fact([value('AUD', 5)], aspects([a - b]), _),
	evaluate_fact(aspects([]), text(Out)).


:- end_tests(facts).
