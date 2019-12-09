from django.http import JsonResponse
import deepdiff, json
import xml
from defusedxml import minidom





def load(fn):
	if fn.lower().endswith('.xml'):
		p = minidom.parse(fn)
		return xml_to_js(p)
	else:
		return json.load(open(fn,'r'))

def has_elements(x):
	for y in x:
		if isinstance(y, xml.dom.minidom.Element):
			return True

def xml_to_js(p):
	r = []
	h = has_elements(p.childNodes)
	for n in p.childNodes:
		if isinstance(n, xml.dom.minidom.Comment):
			pass
		elif isinstance(n, xml.dom.minidom.Element):
			r.append({"a":n.nodeName, "children":xml_to_js(n), "attributes":xml_to_js_attrs(n)})
		elif isinstance(n, xml.dom.minidom.Text):
			if not h:
				try:
					v = float(n.data)
				except ValueError:
					v = n.data
				r.append(v)
	return r

def xml_to_js_attrs(a):
	r = []
	if a.attributes:
		for k,v in a.attributes.items():
			r.append({'k':k,'v':v})
	return r

def index(request):
	""" fixme: limit these to some directories / hosts """
	
	params = request.GET
	a = load(params['a'])
	b = load(params['b'])

	d = deepdiff.DeepDiff(a,b,
		#ignore_order=True,report_repetition=False,
		**json.loads(params['options']),
		ignore_numeric_type_changes=True
	)
	
	for k,v in d.items():
		if isinstance(v, dict):
			for k2,v2 in v.items():
				if "old_value" in v2:
					if "old_type" in v2:
						del v2["old_type"]
					if "new_type" in v2:
						del v2["new_type"]
					v2["<"] = v2["old_value"]
					del v2["old_value"]
					v2[">"] = v2["new_value"]
					del v2["new_value"]
	
	return JsonResponse({'diff':d}, json_dumps_params={'default':str,'indent':4})










