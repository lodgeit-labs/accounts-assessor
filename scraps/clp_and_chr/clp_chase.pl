basic_chase(KB, Model) :-
	collect_facts(KB, Facts),
	collect_rules(KB, Rules),
	basic_chase_helper(Rules, Facts, Model).

basic_chase_helper2(KB, Current_Model, Model) :-
	basic_chase_step(KB, Current_Model, Next_Model, succeed),
	Current_Model \= Next_Model,
	basic_chase_helper2(KB, Next_Model, Model).

basic_chase_helper2(KB, Model, Model) :-
	basic_chase_step(KB, Model, Model, fail).

basic_chase_step(KB, Model, Model, fail) :-
	


chase(KB, Model) :-
	chase_helper(KB, [], Model).

chase_step(KB, ...) :-

chase_body((Head :- Body), Model, Fact) :-
	chase_body_helper(Head, Body, Model, Fact).

chase_body_helper(Head, [Item | Rest], Model, Fact).
	chase_body_item(Item, Model),
	chase_body_helper(Head, Rest, Model, Fact).

chase_body_helper(Head, [], Model, Head).


chase_body_item(Item, [Item | Rest]).
chase_body_item(Item, [X | Rest]) :-
	Item \= X,
	chase_body_item(Rest).

chase_helper([Rule | Rest], Model, [Fact | Model]) :-
	chase_body(Rule, Model, Fact),
chase_helper([


/*
X < 5.
X > 5.

*/	
