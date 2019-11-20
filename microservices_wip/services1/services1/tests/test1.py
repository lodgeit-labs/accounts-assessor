from services1 import solver
import untangle

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

def test1():
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

	f = """
closing_count = opening_count + natural_increase_count + purchases_count - killed_for_rations_count - losses_count - sales_count
natural_increase_value = natural_increase_count * natural_increase_value_per_head
opening_and_purchases_and_increase_count = opening_count + purchases_count + natural_increase_count
opening_and_purchases_value = opening_value + purchases_value
average_cost = opening_and_purchases_value + natural_increase_value / opening_and_purchases_and_increase_count
value_closing = average_cost * closing_count
killed_for_rations_value = killed_for_rations_count * average_cost
closing_and_killed_and_sales_minus_losses_count = sales_count + killed_for_rations_count + closing_count - losses_count
closing_and_killed_and_sales_value = sales_value + killed_for_rations_value + value_closing
revenue = sales_value
livestock_cogs = opening_and_purchases_value - value_closing - killed_for_rations_value
gross_profit_on_livestock_trading = revenue - livestock_cogs
	"""
	return solver.solve_formulas(f, i)


