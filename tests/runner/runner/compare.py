


import json
import subprocess
import shlex



def my_xml_diff(a,b):
	"""
	for div7a results.
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
		yield f'{a.tag}: len({a}) != len({b}): {len(a)} != {len(b)}'
	for i in range(len(a)):
		yield from my_xml_diff(a[i],b[i])



float_comparison_max_difference = 0.0001


# import xmldiff.main, xmldiff.formatting


def xml_delta(a, b):
	"""for xbrl instances"""
	return subprocess.check_output(shlex.split(f"""swipl -s ../../sources/public_lib/lodgeit_solvers/prolog/utils/compare_xml.pl -g "compare_xml_files('{str(a)}', '{str(b)}'),halt." """), universal_newlines=True)



def json_diff(a_path, b_path):
	"""for json reports"""
	a = json.loads(a_path)
	b = json.loads(b_path)
	return json_delta(a, b)



def json_delta(a, b):
	if type(a) is not type(b):
		return f'{type(a)} != {type(b)}'
	if isinstance(a, dict):
		if a.keys() != b.keys():
			return f'{a.keys()} != {b.keys()}'
		for k in a.keys():
			d = json_delta(a[k], b[k])
			if d:
				return d
	elif isinstance(a, list):
		if len(a) != len(b):
			return f'{len(a)} != {len(b)}'
		for i in range(len(a)):
			d = json_delta(a[i], b[i])
			if d:
				return d
	elif isinstance(a, float):
		if abs(a - b) > float_comparison_max_difference:
			return f'{a} != {b}'
	elif a != b:
		return f'{a} != {b}'
