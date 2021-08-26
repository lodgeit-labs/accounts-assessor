#!/usr/bin/env python3



# integration tests

parameters = Dotdict()


for v in find_all_saved_testcases():
	parameters.testcase = v

	for v in ['remote', 'subprocess']:
		parameters.mode = v

		if parameters.mode == 'subprocess':
			for v in [True, False]:
				parameters.die_on_error = v


	member(Testcase, $>find_all_saved_testcases),
	member(Mode, ['remote', 'subprocess']),
	(	Mode == 'subprocess'
	->	member(Die_on_error, [true, false]),
	;	true),



is_prioritized(prioritize, parameters):
	"""tell if a permutation of parameters matches given prioritization rules"""
	for k,v in prioritize.items():
		matches = {}
		if typeof v == Bool:
			if parameters[k] == v:
				matches[k] = True
		if typeof v == Callable:
			if v(parameters[k]):
				matches[k] = True
		if len(matches) == len(prioritize):
			return True




import pytest

def testUnitTests():




def robust_models_are_equivalent(A,B):
    



#if __name__ == '__main__':
#    print_hi('PyCharm')
