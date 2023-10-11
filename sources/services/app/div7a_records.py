
def r(date, type, info):
	return type(date, info)


class loan_start:
	def __init__(self, date, info):
		self.date = date
		self.info = info
	def __repr__(self):
		return 'loan_start({})'.format(self.info)
	def __eq__(self, other):
		return self.date == other.date and self.__class__ == other.__class__ and self.info == other.info
	def __lt__(self, other):
		return (self.date, record_sorting[self.__class__]) < (other.date, record_sorting[other.__class__])

class opening_balance:
	def __init__(self, date, info):
		self.date = date
		self.info = info
	def __repr__(self):
		return 'opening_balance({})'.format(self.info)
	def __eq__(self, other):
		return self.date == other.date and self.__class__ == other.__class__ and self.info == other.info
	def __lt__(self, other):
		return (self.date, record_sorting[self.__class__]) < (other.date, record_sorting[other.__class__])

class interest_accrual:
	def __init__(self, date, info):
		self.date = date
		self.info = info
	def __repr__(self):
		return 'interest_accrual({})'.format(self.info)
	def __eq__(self, other):
		return self.date == other.date and self.__class__ == other.__class__ and self.info == other.info
	def __lt__(self, other):
		return (self.date, record_sorting[self.__class__]) < (other.date, record_sorting[other.__class__])

class repayment:
	def __init__(self, date, info):
		self.date = date
		self.info = info
	def __repr__(self):
		return 'repayment({})'.format(self.info)
	def __eq__(self, other):
		return self.date == other.date and self.__class__ == other.__class__ and self.info == other.info
	def __lt__(self, other):
		return (self.date, record_sorting[self.__class__]) < (other.date, record_sorting[other.__class__])



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

