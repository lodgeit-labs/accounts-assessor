from datetime import date


def r(date, type, info):
	result = type()
	result.date = date
	result.info = info
	return result


class Record:
	date: date
	info: dict

	@property
	def income_year(self) -> int:
		"""
		Calculate the income year based on the date.

		The income year is determined by the year of the date. If the month of the date is less than 7, the income year is the same as the year of the date. Otherwise, the income year is the year of the date plus 1.
		"""
		return self.date.year if self.date.month < 7 else self.date.year + 1
	def __repr__(self):
		return f'{self.date}:{self.__class__.__name__}({self.info})'
	def __eq__(self, other):
		return self.date == other.date and self.__class__ == other.__class__ and self.info == other.info
	def __lt__(self, other):
		return (self.date, record_sorting[self.__class__]) < (other.date, record_sorting[other.__class__])

	def copy(self):
		result = self.__class__()
		result.date = self.date
		result.info = self.info.copy()
		return result

class loan_start(Record):
	pass
class opening_balance(Record):
	pass
class interest_accrual(Record):
	pass
class lodgement(Record):
	pass
class repayment(Record):
	pass
class myr_check(Record):
	pass
class lodgement(Record):
	pass


record_sorting = {
	loan_start: 0,
	opening_balance: 1,
	interest_accrual: 2,
	repayment: 3,
	myr_check: 4,
# todo test repayment *at* lodgement day. What's the legal position?
	lodgement: 5
}


def insert_record(records, record):
	records = records[:] + [record]
	return sort_records(records)


def sort_records(records):

	# sort by date, then by type (so that interest accruals come before repayments)
	records = sorted(records)

	# make sure there is only one interest accrual record per day
	records2 = []
	for r in records:
		if len(records2) == 0:
			records2.append(r)
		elif records2[-1].__class__ == interest_accrual and r.__class__ == interest_accrual and records2[-1].date == r.date:
			pass
		else:
			records2.append(r)
	return records2


def benchmark_rate(year):
	rates = {
		2023: 4.77,
		2022: 4.52,
		2021: 4.52,
		2020: 5.37,
		2019: 5.20,
		2018: 5.30,
		2017: 5.40,
		2016: 5.45,
		2015: 5.95,
		2014: 6.20,
		2013: 7.05,
		2012: 7.80,
		2011: 7.40,
		2010: 5.75,
		2009: 9.45,
		2008: 8.05,
		2007: 7.55,
		2006: 7.3,
		2005: 7.05,
		2004: 6.55,
		2003: 6.3,
		2002: 6.8,
		2001: 7.8,
		2000: 6.5,
		1999: 6.7,
	}
	return rates[year]
