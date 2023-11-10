from datetime import timedelta, date

def ato_date_to_xml(date):
	items = date.split('/') # dmy
	y = int(items[2])
	m = int(items[1])
	d = int(items[0])
	if not (0 < m <= 12):
		raise Exception(f'invalid month: {m}')
	if not (0 < d <= 31):
		raise Exception(f'invalid day: {d}')
	if not (1980 < y <= 2050):
		raise Exception(f'invalid year: {y}')
	return f'{y}-{m:02}-{d:02}' # ymd

def python_date_to_xml(date):
	y = date.year
	m = date.month
	d = date.day
	if not (0 < m <= 12):
		raise Exception(f'invalid month: {m}')
	if not (0 < d <= 31):
		raise Exception(f'invalid day: {d}')
	if not (1980 < y <= 2050):
		raise Exception(f'invalid year: {y}')
	return f'{y}-{m:02}-{d:02}' # ymd

def date_range_inclusive(start, end):
	for n in range((end - start).days + 1):
		yield start + timedelta(n)
