import argparse
import xmlschema
import sys

def main():
	ap = argparse.ArgumentParser(description="Validate XML instance against XSD schema file")
	ap.add_argument("instance", help="XML Instance File")
	ap.add_argument("schema", help="XSD Schema File")
	args = ap.parse_args()
		
	xs = xmlschema.XMLSchema(args.schema)
	try:
		xs.validate(args.instance)
	except:
		sys.exit(1)

if __name__ == "__main__":
	main()
