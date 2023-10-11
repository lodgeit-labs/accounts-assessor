
def r(date, type, info):
	return type(date, info)


class Record:
	def __init__(self, date, type, info):
		self.date = date
		self.info = info
	def __repr__(self):
		return f'{self.date}:{self.__class__.__name__}({self.info})'
	def __eq__(self, other):
		return self.date == other.date and self.__class__ == other.__class__ and self.info == other.info
	def __lt__(self, other):
		return (self.date, record_sorting[self.__class__]) < (other.date, record_sorting[other.__class__])

class loan_start(Record):
	pass

class opening_balance:
	pass

class interest_accrual:
	pass

class repayment:
	pass


record_sorting = {
	loan_start: 0,
	opening_balance: 1,
	interest_accrual: 2,
	repayment: 3,
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

