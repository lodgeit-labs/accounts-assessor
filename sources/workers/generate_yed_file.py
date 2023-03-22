import pyyed


def generate_yed_file(g0, tmp_path):
	go = pyyed.Graph()
	added = set()
	for (s, p, o, c) in g0.quads(None):
		add_node(go, added, s)
		add_node(go, added, o)
		go.add_edge(s, o, label=p)
	go.write_graph(tmp_path + '/doc.yed.graphml', pretty_print=True)


prefixes = [
	('xml', 'http://www.w3.org/XML/1998/namespace#'),
	('xsd', 'http://www.w3.org/2001/XMLSchema#'),
	('l', 'https://rdf.lodgeit.net.au/v1/request#')
	]
prefixes.sort(key=len)


def add_node(go, added, x):
	if x not in added:
		added.add(x)
		print("len(added): "+str(len(added)) + "...", file=sys.stderr)

		kwargs = {}

		#parsed = urllib.parse.urlparse(x)
		#fragment = parsed.fragment
		#if fragment != '':

		for shorthand, uri in prefixes:
			if x.startswith(uri):
				kwargs['label'] = shorthand + x[len(uri):]
				break

		go.add_node(x, shape_fill="#DDDDDD", **kwargs)

		# uEd can display a (clickable?) URL, but that has to be specified like:
		# <data key="d3" xml:space="preserve"><![CDATA[http://banana.pie]]></data>
		# if you want to see it, go to yEd, assign the URL property on a node and save the file.
		# etree doesn't support writing out CDATA.
		# workarounds:
		# https://stackoverflow.com/questions/174890/how-to-output-cdata-using-elementtree
		# possible solution: replace etree from underneath pyyed with lxml, it has a compatible api(?)

		# at any case, at about 1000 nodes, since we're building up the xml dom in memory, this script slows down to a crawl. So we need a custom solution that doesn't use pyyed and saves the generated xml immediately, rather than building up the full dom first.
		# however, yed itself is not suitable for thousands of nodes: https://yed.yworks.com/support/qa/11879/maximum-number-of-nodes-that-yed-can-handle

		#other options: run python with -O, use cpython..
