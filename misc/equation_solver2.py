
	
class Solution:
	cost = 0
	value = None
	original_formula = None
	rearranged_formula = None

def solutions(inputs, formulas):
	variables_to_solve = []
	for f in formulas:
		variables_to_solve += f.vars()

	solutions = {}
	failures = {}

	for k,v in inputs:
		solutions[k] = Solution()
		solutions[k].value = v

	def solve(v):
		if v in failures + solutions: return
		for f in original_formulas:
			for r in rearrange_for(f, v):
				for free_var in vars_without_substitutions(r):
					solve(free_var)
				if vars_without_substitutions(r) = []:
					solutions[v] = Solution()
					solutions[v].value = evaluate(r)
					solutions[v].cost = sum([x.cost for x in vars(r)])

	def evaluate(f):
		subs = dict([k,s.value for k,s in solutions.items()])
		f.subs(subs)..?

	for v in variables to solve:
		solve(v)
	

def rearrange_for(f, v):
	# can be a no-op for livestock
	return f

solve_livestock():
	i = get_input()
	f = get_formulas()
	print(solutions(i, f))
	
get_input():
	req = """<?xml version="1.0"?>
<reports xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <livestockaccount>
    <generator>
      <date>2017-03-25T05:53:43.887542Z</date>
      <source>ACCRIP</source>
      <author>
        <firstname>waqas</firstname>
        <lastname>awan</lastname>
        <company>Uhudsoft</company>
      </author>
    </generator>
    <company>
      <abn>12345678900</abn>
      <tfn />
      <clientcode />
      <anzsic />
      <notes />
      <directors />
    </company>
    <title>Livestock Account Details</title>
    <period>1 July, 2014 to 30 June, 2015</period>
    <startDate>2014-07-01</startDate>
    <endDate>2015-06-30</endDate>
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
	for e in p.reports.livestockaccount.livestocks.livestock.children:
		try:
			inputs[e.name] = int(e.cdata)
		except:
			pass
	return inputs


	

def get_formulas():
	text = """
		eq(Stock_on_hand_at_end_of_year_count,Stock_on_hand_at_beginning_of_year_count + Natural_increase_count + Purchases_count - Killed_for_rations_count - Losses_count - Sales_count)
		
		eq(Natural_Increase_value, Natural_increase_count * Natural_increase_value_per_head)
		
		eq(Opening_and_purchases_and_increase_count, Stock_on_hand_at_beginning_of_year_count + Purchases_count + Natural_increase_count)
		
		eq(Opening_and_purchases_value, Stock_on_hand_at_beginning_of_year_value + Purchases_value)
		
		eq(Average_cost, (Opening_and_purchases_value + Natural_Increase_value) /  Opening_and_purchases_and_increase_count)
		
		
		
		eq(Stock_on_hand_at_end_of_year_value, Average_cost * Stock_on_hand_at_end_of_year_count)
		
		eq(Killed_for_rations_value, Killed_for_rations_count * Average_cost)
		
		eq(Closing_and_killed_and_sales_minus_losses_count, Sales_count + Killed_for_rations_count + Stock_on_hand_at_end_of_year_count - Losses_count)
		
		eq(Closing_and_killed_and_sales_value, Sales_value + Killed_for_rations_value + Stock_on_hand_at_end_of_year_value)
		
		eq(Revenue, Sales_value)
		
		eq(Livestock_COGS, Opening_and_purchases_value - Stock_on_hand_at_end_of_year_value - Killed_for_rations_value)
		
		eq(Gross_Profit_on_Livestock_Trading, Revenue - Livestock_COGS)
	"""
	formulas = [y for y in [x.strip() for x in text.splitlines()] if 'eq(' in y]
	from sympy.parsing import sympy_parser 
	eqs = [sympy_parser.parse_expr(x) for x in formulas]
	return eqs

		
	
	
	
	
	
	
	
