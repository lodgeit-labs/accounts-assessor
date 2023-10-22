from datetime import date


uuid = 0
def new_uuid():
	global uuid
	uuid += 1
	return uuid



def record(date, type, info):
	result = type(date)
	result.info = info
	return result


class Record:
	uuid: int
	date: date
	info: dict

	def __init__(self, date=None, info=None):
		self.uuid = new_uuid()
		self.date = date
		self.info = {} if info is None else info
		self.final_balance = None
		self.year = None
		self.remaining_term = None

	def copy(self):
		result = self.__class__()
		result.uuid = self.uuid
		result.date = self.date
		result.info = self.info.copy()
		result.final_balance = self.final_balance
		result.year = self.year
		result.remaining_term = self.remaining_term
		return result

	def __eq__(self, other):
		return (self.__class__ == other.__class__ and
				self.uuid == other.uuid and
				self.date == other.date and 
				self.info == other.info and
				self.final_balance == other.final_balance and
				self.year == other.year and
				self.remaining_term == other.remaining_term
		)

	@property
	def income_year(self) -> int:
		"""
		Calculate the income year based on the date.
		The income year is determined by the year of the date. If the month of the date is less than 7, the income year is the same as the year of the date. Otherwise, the income year is the year of the date plus 1.
		"""
		return self.date.year if self.date.month < 7 else self.date.year + 1

	def __repr__(self):
		return f'{self.date}:{self.__class__.__name__}({self.info})'
	def __lt__(self, other):
		x = 0
		goes_before_any = self.info.get('goes_before_any')
		if goes_before_any:
			for type in goes_before_any:
				if isinstance(other, type):
					x = -1
		return (self.date, x, record_sorting[self.__class__]) < (other.date, 0, record_sorting[other.__class__])

class loan_start(Record):
	"""
	carries the principal and term of the loan, but these are invariants of the computation, there is no meaning to them being specified in a record inserted into a particular position in the records list. 
	"""
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

class calculation_start(Record):
	pass

class calculation_end(Record):
	pass
class loan_term_end(Record):
	pass

record_sorting = {
	calculation_start: 0,
	loan_start: 1,
	interest_accrual: 2,
	repayment: 3,
	lodgement: 4,
	# todo test repayment *at* lodgement day. What's the legal position?
	myr_check: 5,
	opening_balance: 6,
	calculation_end: 7,
	loan_term_end: 8,
}



"""
virtually speaking, wrt user input, reepayments are always situated between an opening balance (if there are repayments before opening balance, that's either to be ignored or we should warn about it, not sure, but it doesn't seem like something people would normally do), and if there are repayments after calculation year, idk, that's alright i guess, we can just ignore them, or warn about them, but it's not a problem.



"""