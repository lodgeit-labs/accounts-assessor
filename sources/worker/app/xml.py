import xmlschema



schemas = {}


def parse_schema(xsd):
	"""
	:param source: an URI that reference to a resource or a file path or a file-like \
	    object or a string containing the schema or an Element or an ElementTree document \
	    or an :class:`XMLResource` instance. A multi source initialization is supported \
	    providing a not empty list of XSD sources.

	:param allow: defines the security mode for accessing resource locations. Can be \
	    'all', 'remote', 'local' or 'sandbox'. Default is 'all' that means all types of \
	    URLs are allowed. With 'remote' only remote resource URLs are allowed. With 'local' \
	    only file paths and URLs are allowed. With 'sandbox' only file paths and URLs that \
	    are under the directory path identified by source or by the *base_url* argument \
	    are allowed.
	"""

	# this is overly strict, we will need to allow our schemes directory, at least

	return xmlschema.XMLSchema(xsd, allow='none', defuse='always')

def get_schema(xsd):
	if xsd in schemas:
		schema = schemas[xsd]
	else:
		schema = parse_schema(xsd)
		schemas[xsd] = schema
	return schema

