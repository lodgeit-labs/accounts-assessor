import diskcache
import requests



cache = diskcache.Cache('../../cache/exchange_rates')



import logging

log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
log.debug("debug exchange_rates.py")



def get_rates(date):
	rate = cache.get(date)
	if rate is not None:
		return rate
	return get_rates2(date)
	

@diskcache.barrier(cache, diskcache.Lock)
def get_rates2(date):
	rate = cache.get(date)
	if rate is not None:
		return rate
	
	
	log.debug('started %s', date)
	result = requests.get("http://openexchangerates.org/api/historical/" + date + ".json?app_id=677e4a964d1b44c99f2053e21307d31a")
	result.raise_for_status()
	result = result.json()
	log.debug('finished %s', date)
	
	
	cache.set(date, result)
	return result 


