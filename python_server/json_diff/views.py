from django.http import JsonResponse
import deepdiff, json
import xml
from defusedxml import minidom
import subprocess




def load(fn):
	if fn.lower().endswith('.xml'):
		p = minidom.parse(fn)
		cleanup(p)
		return p
		#return xml_to_js(p)
	else:
		return json.load(open(fn,'r'))

def has_elements(x):
	for y in x:
		if isinstance(y, xml.dom.minidom.Element):
			return True

def xml_to_js_attrs(a):
	r = []
	if a.attributes:
		for k,v in a.attributes.items():
			r.append({'k':k,'v':v})
	return r

def xml_to_js(p):
	assert(isinstance(p, xml.dom.minidom.Element))
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

def cleanup(p):
	"""
	:param x: minidom DOM
	clean up our flavor of xml.
	text with element siblings is removed,
	comments are removed
	"""
	assert(isinstance(p, xml.dom.minidom.Element))
	h = has_elements(p.childNodes)
	for ch in p.childNodes[:]:
		if isinstance(ch, xml.dom.minidom.Comment):
			p.childNodes.remove(ch)
		elif h and isinstance(n, xml.dom.minidom.Text):
			p.childNodes.remove(ch)
		else:
			cleanup(ch)

def xmldiff(a,b):
	p1 = Popen(['../python/venv/bin/xmldiff', a,b], stdout=PIPE, stderr=subprocess.STDOUT)
	p2 = Popen(shlex.split("""grep -v -F '[update-text-after, /' | grep -v -F '[insert-comment, /' | grep -v -F '/comment()['"""), stdin=p1.stdout, stdout=PIPE)
	p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits before p1.
	return p2.communicate()



def index(request):
	""" fixme: limit these to some directories / hosts """
	
	params = request.GET
	a_fn = params['a']
	b_fn = params['b']
	a = load(a_fn)
	b = load(b_fn)

	if a_fn.lower().endswith('.xml'):
		d = xmldiff(a,b)
	else:
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










