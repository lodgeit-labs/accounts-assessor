from datetime import timedelta, date


def date_range_inclusive(start, end):
	for n in range((end - start).days + 1):
		yield start + timedelta(n)
