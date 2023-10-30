def my_xml_diff(a,b):
	"""
	see scraps.py for more info on generic xml comparison
	this is the best i can get so far.
	could use some tests.
	"""
	if a.tag != b.tag:
		yield f'{a.tag} != {b.tag}'
	if a.attrib != b.attrib:
		yield f'{a.tag}: {a.attrib} != {b.attrib}'
	if a.text != b.text:
		try:
			af = float(a.text)
			bf = float(b.text)
			# a bit for float errors, and a bit for ato calc rounding
			if abs(af - bf) > 0.003 + 0.5:
				yield  f'{a.tag}: {af:.20f} !~= {bf:.20f}'
		except ValueError:
			yield f'{a.tag}: {a.text} != {b.text}'
	if len(a) != len(b):
		yield f'{a.tag}: len({a}) != len({b})'
	for i in range(len(a)):
		yield from my_xml_diff(a[i],b[i])
