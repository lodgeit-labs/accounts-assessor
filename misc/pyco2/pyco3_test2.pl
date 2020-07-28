:- ['../../sources/public_lib/lodgeit_solvers/prolog/pyco2/pyco3.pl'].

r(	fr(L,F,R)
		,first(L, F)
		,rest(L, R)
	,n-'list cell helper'
).


r(	exists-('list cell', ['rdf:first','rdf:rest'])
	,n-'"All lists exist" - https://www.w3.org/TeamSubmission/n3/'
).
