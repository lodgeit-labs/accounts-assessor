from django.http import JsonResponse
import deepdiff, json
import xml
from defusedxml import minidom
import subprocess, shlex
import tempfile, os



def load(fn):
	if fn.lower().endswith('.xml'):
		p = minidom.parse(fn)
		cleanup(p)
		return p
		#return xml_to_js(p)
	else:
		return json.load(open(fn,'br'))

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
	assert(isinstance(p, (xml.dom.minidom.Element, xml.dom.minidom.Document)))
	h = has_elements(p.childNodes)
	for ch in p.childNodes[:]:
		#print(type(ch))
		if isinstance(ch, xml.dom.minidom.Comment):
			p.childNodes.remove(ch)
		elif isinstance(ch, xml.dom.minidom.Text):
			if h:
				p.childNodes.remove(ch)
		else:
			cleanup(ch)

tempdir = tempfile.mkdtemp(prefix='xmldiff')

def tmpfw(tempdir):
	fd,fn = tempfile.mkstemp(prefix='xmldiff', dir=tempdir, text=True)
	return os.fdopen(fd,'w'), fn

def tmpfw_and_write_xml(tempdir, a_dom):
	f,fn = tmpfw(tempdir)
	a_dom.writexml(f,newl='\n')
	f.close()
	return fn

def xmldiff(a_dom,b_dom):
	a = tmpfw_and_write_xml(tempdir, a_dom)
	b = tmpfw_and_write_xml(tempdir, b_dom)

	p1 = subprocess.Popen(['diff', '--color=always', a, b], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
	#p1 = Popen(['../python/venv/bin/xmldiff', '-F', '1', a, b], stdout=PIPE, stderr=subprocess.STDOUT)
	#p2 = Popen(shlex.split("""grep -v -F '[update-text-after, /' | grep -v -F '[insert-comment, /' | grep -v -F '/comment()['"""), stdin=p1.stdout, stdout=PIPE)
	p2 = subprocess.Popen(shlex.split("""cat"""), stdin=p1.stdout, stdout=subprocess.PIPE, universal_newlines=True)
	p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits before p1.
	return p2.communicate()[0]



def diff(file_a: str, file_b:str, options: dict):
	return do_diff(file_a, file_b, options)

def do_diff(a_fn, b_fn, options={}):
	""" fixme: limit these to some directories / hosts """
	a = load(a_fn)
	b = load(b_fn)

	if a_fn.lower().endswith('.xml'):
		msg = xmldiff(a,b)
		d = 'yes'
	else:
		d = deepdiff.DeepDiff(a,b,
			#ignore_order=True,report_repetition=False,
			**options,
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
		msg = ''
	return {'diff':d, 'msg':msg}



#import IPython; IPython.embed()
