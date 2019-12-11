"""
just the basic gaussian elimination thingy or something like that
only for the case where each formula can be solved separately
which i think would still be good enough to let us write IR fully declaratively and have it deal with absence of exchange rates and with selling with different currency than buying
"""


from services1.formula_parser import parse_formulas
#import sympy
import logging



logger = logging.getLogger()
dbg = logger.debug



def union(d1, d2):
	"""return a new dict that is the union of d1 and d2"""
	c = d1.copy()
	c.update(d2)
	return c



class E:
	"""a mathematical expression"""
	def __init__(s, items):
		s.op = items[0]
		s.args = []
		for x in items[1:]:
			if isinstance(x, list):
				a = E(x)
			else:
				a = x
			s.args.append(a)
	def vars(s):
		r = []
		for x in s.args:
			if isinstance(x, E):
				r = r + x.vars()
			elif x.isidentifier():
				r.append(x)
		#dbg('vars:', s, r)
		return r
	def __repr__(s):
		return s.op+ '' + str(s.args) + ''
	def __str__(s):
		if len(s.args) == 1:
			return s.op + str(s.args[0])
		elif len(s.args) == 2:
			return str(s.args[0]) + ' ' + s.op + ' ' + str(s.args[1])
		else:
			return s.op+ '' + str(s.args)
	def isolate(s, v):
		"""
			(symbolically) isolate variable v
			would re-arrange the formula so that the variable being solved(v) is on the lhs of the '=', by itself
			this is kinda just a presentation thing. Also fail if the formula cannot be rearranged that way (maybe doesnt contain the variable at all)
			can be a no-op for standalone livestock formulas.
		"""
		if s.args[0] != v: return
		return s
	def with_substs(self, substs):
		args = []
		for a in self.args:
			if isinstance(a, E):
				args.append(a.with_substs(substs))
			else:
				assert(a.isidentifier())
				if a in substs:
					r = substs[a].value
				else:
					r = a
				args.append(r)
		return self.__class__([self.op] + args)


class Solution:
	cost = 0
	value = None
	source = None
	isolation = None
	def __repr__(s):
		return 'S(' + str(s.value) + ')'


def get_variables_to_solve(formulas):
	variables_to_solve = set()
	for f in formulas:
		for v in f.vars():
			variables_to_solve.add(v)
	return variables_to_solve


def solutions(inputs, formulas):
	"""
	inputs: a dict from variable name string to number/other value
	"""

	variables_to_solve = get_variables_to_solve(formulas)

	#substitutions and failures and stack are each just a "global" for all these nested functions
	solutions = {}
	failures = {}
	stack = []
	
	for k,v in inputs.items():
		solutions[k] = Solution()
		solutions[k].value = v
		solutions[k].source = '(input)'
	
	def solve(v):
		# if variable already solved or found unsolvable, give up
		if v in union(failures, solutions): return

		# if v is already being solved, give up, prevent infinite recursion 
		if v in stack: return
		stack.append(v)

		dbg('solving ' + v)

		for f in formulas:
			r = f.isolate(v)
			if r == None: continue 
			# formula does not contain the variable or could not be rearranged. this should probably use substitutions found so far
			
			for free_var in eq_rhs_vars_without_substitutions(r):
				if free_var != v: solve(free_var)
				
			if eq_rhs_vars_without_substitutions(r) == [v]:
				dbg('new solution')
				new_v = evl(r)
				s = Solution()
				s.value = new_v
				s.source = f
				s.isolation = r
				solutions[v] = s
				#dbg('r:', r)
				vs = r.vars()
				#dbg('vs:', vs)
				solutions[v].cost = sum([solutions[x].cost for x in vs if x != v])
			else:
				dbg('new failure')
				#failures[v] = True # i dont think this situation should be regarded as a failure, because a variable could fail solving for the reason of already being in stack
		stack.pop()

	def evl(t):
		#dbg('evl:', t)
		#dbg('sols:', solutions)
		if isinstance(t, str):
			return solutions[t].value
		op = t.op
		if op == '=':
			return evl(t.args[1])
		vs = [evl(x) for x in t.args]
		if op == '+':
			return vs[0] + vs[1]
		if op == '-':
			if len(vs) == 2:
				return vs[0] - vs[1]
			else:
				return -vs[0]
		if op == '/':
			return vs[0] / vs[1]
		if op == '*':
			return vs[0] * vs[1]		

	def eq_rhs_vars_without_substitutions(f):
		r = [x for x in f.vars() if x not in solutions.keys()]
		#dbg('vars_without_substitutions:', r)
		return r

	dbg('solutions before:', solutions)
	for v in variables_to_solve:
		solve(v)
	dbg('solutions after:', solutions)
	#dbg('failures after:', failures)
	return solutions


def response_body(solutions):
	"""
	what we should do here is construct a wrapper json response that contains a serialized json response and a serialized xml response. The prolog side would then write them into tmp and take care of attaching a vue viewer
	"""
	r = {}
	for k,s in solutions.items():
		item = {'value':s.value}
		
		if 'isolation' in s.__dict__:
			item['isolation'] = str(s.isolation)
			item['isolation_with_substs'] = str(s.isolation.with_substs(solutions))

		r[k] = item
	return r




def get_formulas(formulas_text):
	formulas = [E(x) for x in [parse_formulas(formulas_text)]]
	return formulas

		
def solve_formulas(formulas_text, inputs):
	f = get_formulas(formulas_text)
	return solutions(inputs, f)





"""
something we can do is switch from simple identifier strings to urls. Probably each formula etc being a rdf resource.
"apply" predicate applying formulas to a first-class livestockData object. Apply would be a "built-in" that takes 
livestockData and produces a new livestockData with stuff filled in, explanations added. 

#1 doing livestock totals is just special-purpose piece of code in apply
#2 "livestockCalculator formulas applied to each livestock", "sum of revenue of each livestock"
...
"""
