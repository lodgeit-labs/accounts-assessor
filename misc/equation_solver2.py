"""
just the basic gaussian elimination thingy or something like that
only for the case where each formula can be solved separately
which i think would still be good enough to let us write ir fully declaratively and have it deal with absence of exchange rates and with selling with different currency than buying
"""

def union(d1, d2):
	c = d1.copy()
	c.update(d2)
	return c

class F:
	def __init__(s, items):
		s.items = []
		for x in items:
			if isinstance(x, list):
				a = F(x)
			else:
				a = x
			s.items.append(a)
	def vars(s):
		r = []
		for x in s.items:
			if isinstance(x, F):
				r = r + x.vars()
			elif x.isidentifier():
				r.append(x)
		print('vars:', s, r)
		return r
	def __repr__(s):
		return 'F(' + str(s.items) + ')'

class Solution:
	cost = 0
	value = None
	original_formula = None
	rearranged_formula = None
	def __repr__(s):
		return 'S(' + str(s.value) + ')'

def solutions(inputs, formulas):
	variables_to_solve = []
	for f in formulas:
		variables_to_solve += f.vars()

	solutions = {}
	failures = {}
	stack = []
	
	for k,v in inputs.items():
		solutions[k] = Solution()
		solutions[k].value = v
	
	def solve(v):
		if v in union(failures, solutions): return
		if v in stack: return
		stack.append(v)
		for f in formulas:
			r = rearrange_for(f, v)
			if r.items[1] != v: continue
			for free_var in vars_without_substitutions(r):
				solve(free_var)
			if vars_without_substitutions(r) == []:
				print('new solution')
				new_v = evl(r)
				solutions[v] = Solution()
				solutions[v].value = new_v
				print('r:', r)
				vs = r.vars()
				print('vs:', vs)
				solutions[v].cost = sum([solutions[x].cost for x in vs if x != v])
			else:
				print('new failure')
				failures[v] = True
		stack.pop()

	def evl(t):
		print('evl:', t)
		print('sols:', solutions)
		if isinstance(t, str):
			return solutions[t].value
		op = t.items[0]
		if op == '=':
			return evl(t.items[2])
		vs = [evl(x) for x in t.items[1:]]
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

	def vars_without_substitutions(f):
		return vars_without_substitutions2(0, f)
	
	def vars_without_substitutions2(depth, f):
		print('vars_without_substitutions', depth, '(',f,')')
		if isinstance(f, str):
			vars = [f]
		elif f.items[0] == '=':
			vars = vars_without_substitutions2(depth + 1, f.items[2])
		else:
			vars = f.vars()
		r = [x for x in vars if x not in solutions.keys()]
		print('vars_without_substitutions', depth, ':', r)
		return r

	print('solutions before:', solutions)
	for v in variables_to_solve:
		solve(v)
	print('solutions after:', solutions)
	print('failures after:', failures)
	

def rearrange_for(f, v):
	# can be a no-op for livestock
	return f

def get_input():
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
	from untangle import untangle
	p = untangle.parse(req)
	inputs = {}
	e = p.reports.livestockaccount.livestocks.livestock
	inputs['name'] = e.name.cdata
	inputs['natural_increase_value_per_head'] = int(e.naturalIncreaseValuePerUnit.cdata)
	inputs['losses_count'] = int(e.unitsDeceased.cdata)
	inputs['killed_for_rations_count'] = int(e.unitsRations.cdata)
	inputs['sales_count'] = int(e.unitsSales.cdata)
	#inputs['purchases_count'] = int(e.unitsPurchases.cdata)
	inputs['natural_increase_count'] = int(e.unitsBorn.cdata)
	inputs['opening_count'] = int(e.unitsOpening.cdata)
	inputs['opening_value'] = int(e.openingValue.cdata)
	inputs['sales_value'] = int(e.saleValue.cdata)
	inputs['purchases_value'] = int(e.purchaseValue.cdata)
	return inputs

def get_formulas():
	formulas = [F(x) for x in [
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
		
def solve_livestock():
	i = get_input()
	f = get_formulas()
	print(solutions(i, f))
	
if __name__ == '__main__':
	solve_livestock()
