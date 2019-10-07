from django.http import HttpResponse
from django.shortcuts import render
import untangle
#from sympy import *


"""
just the basic gaussian elimination thingy or something like that
only for the case where each formula can be solved separately
which i think would still be good enough to let us write ir fully declaratively and have it deal with absence of exchange rates and with selling with different currency than buying
"""

def union(d1, d2):
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
		#print('vars:', s, r)
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
	original_formula = None
	rearranged_formula = None
	def __repr__(s):
		return 'S(' + str(s.value) + ')'

def get_variables_to_solve(formulas):
	variables_to_solve = set()
	for f in formulas:
		for v in f.vars():
			variables_to_solve.add(v)
	return variables_to_solve

def solutions(inputs, formulas):
	variables_to_solve = get_variables_to_solve(formulas)

	#substitutions and failures and stack are each just a "global" for all these nested functions
	solutions = {}
	failures = {}
	stack = []
	
	for k,v in inputs.items():
		solutions[k] = Solution()
		solutions[k].value = v
	
	def solve(v):
		# if variable already solved or found unsolvable, give up
		if v in union(failures, solutions): return

		# if v is already being solved, give up, prevent infinite recursion 
		if v in stack: return
		stack.append(v)

		print('solving ' + v)

		for f in formulas:
			r = f.isolate(v)
			if r == None: continue 
			# formula does not contain the variable or could not be rearranged. this should probably use substitutions found so far
			
			for free_var in eq_rhs_vars_without_substitutions(r):
				if free_var != v: solve(free_var)
				
			if eq_rhs_vars_without_substitutions(r) == [v]:
				print('new solution')
				new_v = evl(r)
				s = Solution()
				s.value = new_v
				s.isolation = r
				solutions[v] = s
				#print('r:', r)
				vs = r.vars()
				#print('vs:', vs)
				solutions[v].cost = sum([solutions[x].cost for x in vs if x != v])
			else:
				print('new failure')
				#failures[v] = True # i dont think this situation should be regarded as a failure, because a variable could fail solving for the reason of already being in stack
		stack.pop()

	def evl(t):
		#print('evl:', t)
		#print('sols:', solutions)
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
		#print('vars_without_substitutions:', r)
		return r

	print('solutions before:', solutions)
	for v in variables_to_solve:
		solve(v)
	print('solutions after:', solutions)
	print('failures after:', failures)
	return solutions


def response_body(solutions):
	"""
	what we should do here is construct a wrapper json response that contains a serialized json response and a serialized xml response. The prolog side would then write them into tmp and take care of attaching a vue viewer
	"""
	r = ''
	br = '\n'
	for k,s in solutions.items():
		r += k + ': ' + str(s.value)
		if 'isolation' in s.__dict__:
			r += br + str(s.isolation) + br + str(s.isolation.with_substs(solutions)) + br
		else:
			r += '(input)'
		r += br
	return r

def get_inputs(request_xml_text):
	inputs = {}
	p = untangle.parse(request_xml_text)
	e = p.reports.livestockaccount.livestocks.livestock
	inputs['name'] = e.name.cdata
	inputs['natural_increase_value_per_head'] = int(e.naturalIncreaseValuePerUnit.cdata)
	inputs['losses_count'] = int(e.unitsDeceased.cdata)
	inputs['killed_for_rations_count'] = int(e.unitsRations.cdata)
	inputs['sales_count'] = int(e.unitsSales.cdata)
	inputs['purchases_count'] = int(e.unitsPurchases.cdata)
	inputs['natural_increase_count'] = int(e.unitsBorn.cdata)
	inputs['opening_count'] = int(e.unitsOpening.cdata)
	inputs['opening_value'] = int(e.openingValue.cdata)
	inputs['sales_value'] = int(e.saleValue.cdata)
	inputs['purchases_value'] = int(e.purchaseValue.cdata)
	return inputs

def get_formulas():
	formulas = [E(x) for x in [
		# generated by misc/livestock_formulas_generator.pl
		["=","closing_count",["-",["-",["-",["+",["+","opening_count","natural_increase_count",],"purchases_count",],"killed_for_rations_count",],"losses_count",],"sales_count",],],
		["=","natural_increase_value",["*","natural_increase_count","natural_increase_value_per_head",],],
		["=","opening_and_purchases_and_increase_count",["+",["+","opening_count","purchases_count",],"natural_increase_count",],],
		["=","opening_and_purchases_value",["+","opening_value","purchases_value",],],
		["=","average_cost",["/",["+","opening_and_purchases_value","natural_increase_value",],"opening_and_purchases_and_increase_count",],],
		["=","value_closing",["*","average_cost","closing_count",],],
		["=","killed_for_rations_value",["*","killed_for_rations_count","average_cost",],],
		["=","closing_and_killed_and_sales_minus_losses_count",["-",["+",["+","sales_count","killed_for_rations_count",],"closing_count",],"losses_count",],],
		["=","closing_and_killed_and_sales_value",["+",["+","sales_value","killed_for_rations_value",],"value_closing",],],
		["=","revenue","sales_value",],
		["=","livestock_cogs",["-",["-","opening_and_purchases_value","value_closing",],"killed_for_rations_value",],],
		["=","gross_profit_on_livestock_trading",["-","revenue","livestock_cogs",],],
	]]
	return formulas

"""
something we can do is switch from simple identifier strings to urls. Probably each formula etc being a rdf resource.
"apply" predicate applying formulas to a first-class livestockData object. Apply would be a "built-in" that takes 
livestockData and produces a new livestockData with stuff filled in, explanations added. 

#1 doing livestock totals is just special-purpose piece of code in apply
#2 "livestockCalculator formulas applied to each livestock", "sum of revenue of each livestock"
...
"""
		
def solve_livestock():
	req = """<?xml version="1.0"?>
<reports xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <livestockaccount>
    <livestocks>
      <livestock>
        <name>Sheep</name>
        <currency>AUD</currency>
        <naturalIncreaseValuePerUnit>20</naturalIncreaseValuePerUnit>
        <openingValue>1234</openingValue>
        <saleValue>0</saleValue>
        <purchaseValue>0</purchaseValue>
        <unitsOpening>27</unitsOpening>
        <unitsBorn>62</unitsBorn>
        <unitsPurchases>0</unitsPurchases>
        <unitsSales>0</unitsSales>
        <unitsRations>0</unitsRations>
        <unitsDeceased>1</unitsDeceased>    
        <unitsClosing>88</unitsClosing>
      </livestock>
    </livestocks>
  </livestockaccount>
</reports>
	"""
	i = get_inputs(req)
	f = get_formulas()
	return solutions(i, f)

def livestock_response_html():
	solutions = solve_livestock()
	return "<html><body>\n" + response_body(solutions).replace('\n', '<br>\n') + "\n</body></html>"


if __name__ == '__main__':
	print(livestock_response_html())


def index(request):
	return HttpResponse(livestock_response_html())

