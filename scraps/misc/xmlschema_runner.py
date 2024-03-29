""" a command-line tool to validate a xml against a xsd """

#importing xmlschema takes about 300ms, loading a simple xsd takes also about 300ms, loading Reports.xsd takes almost a second. Running python with -O makes things worse. Validation is almost instant. 

import argparse
import xmlschema
import sys

def main():
	ap = argparse.ArgumentParser(description="Validate XML instance against XSD schema file")
	ap.add_argument("instance", help="XML Instance File")
	ap.add_argument("schema", help="XSD Schema File")
	args = ap.parse_args()
	
	xs = xmlschema.XMLSchema(args.schema)
	xs.validate(args.instance)

if __name__ == "__main__":
	main()
