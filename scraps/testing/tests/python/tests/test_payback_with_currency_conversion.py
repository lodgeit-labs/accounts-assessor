# importing the requests library 
import requests 
from bs4 import BeautifulSoup as bs 

# defining the api-endpoint 
API_ENDPOINT = "http://localhost/prolog/api/ledger"

def test():	
	with open('test_payback_with_currency_conversion.xml') as f:
		data = f.read()

	headers = {'content-type': 'application/xml',
			   'Accept': 'application/xml'}

	# sending post request and saving response as response object 
	r = requests.post(url = API_ENDPOINT, data = data, headers = headers) 

	# extracting response text 
	content = r.text 
	
	soup = bs(content, 'xml')

	assets = soup.find_all('basic:Assets')
	assert len(assets) == 1
	asset_value =  round(float(assets[0].get_text()), 2)
	assert asset_value == -13.51  # to update to value for expected value
	
	current_assets = soup.find_all('basic:CurrentAssets')
	assert len(current_assets) == 1
	current_assets_value =  round(float(current_assets[0].get_text()), 2)
	assert current_assets_value == -13.51  # to update to value for expected value
	
	cash_cash_equivalents = soup.find_all('basic:CashAndCashEquivalents')
	assert len(cash_cash_equivalents) == 1
	cash_cash_equivalents_value =  round(float(cash_cash_equivalents[0].get_text()), 2)
	assert cash_cash_equivalents_value == -13.51  # to update to value for expected value
	
	wells_fargo = soup.find_all('basic:WellsFargo')
	assert len(wells_fargo) == 1
	wells_fargo_value =  round(float(wells_fargo[0].get_text()), 2)
	assert wells_fargo_value == -13.51  # to update to value for expected value
	
	non_current_assets = soup.find_all('basic:NoncurrentAssets')
	assert len(non_current_assets) == 0
	
	financial_investments = soup.find_all('basic:FinancialInvestments')
	assert len(financial_investments) == 0
	
	earnings = soup.find_all('basic:Earnings')
	assert len(earnings) == 1
	earnings_value =  round(float(earnings[0].get_text()), 2)
	assert earnings_value == 13.51 # to update to value for expected value
	
	current_earnings_losses = soup.find_all('basic:CurrentEarningsLosses')
	assert len(current_earnings_losses) == 1
	current_earnings_losses_value =  round(float(current_earnings_losses[0].get_text()), 2)
	assert current_earnings_losses_value ==  13.51  # to update to value for expected value
	
	

    
