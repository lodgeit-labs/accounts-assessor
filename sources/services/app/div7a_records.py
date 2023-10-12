
def r(date, type, info):
	return type(date, info)


class Record:
	def __init__(self, date, info:dict):
		self.date = date
		self.info = info

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

class loan_start(Record):
	pass

class opening_balance:
	pass

class interest_accrual:
	pass

class lodgement:
	pass


class repayment:
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

