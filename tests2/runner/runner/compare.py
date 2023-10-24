def my_xml_diff(a,b):
	"""
	see scraps.py for more info on generic xml comparison
	this is the best i can get so far.
	could use some tests.
	"""
	if a.tag != b.tag:
		return f'{a.tag} != {b.tag}'
	if a.attrib != b.attrib:
		return f'{a.attrib} != {b.attrib}'
	if a.text != b.text:
		try:
			af = float(a.text)
			bf = float(b.text)
			# a bit for float errors, and a bit for ato calc rounding
			if abs(af - bf) > 0.002 + 0.5:
				return  f'{af:.20f} !~= {bf:.20f}'
		except ValueError:
			return f'{a.text} != {b.text}'
	if len(a) != len(b):
		return f'len({a}) != len({b})'
	for i in range(len(a)):
		r = my_xml_diff(a[i],b[i])
		if r is not None:
			return r
