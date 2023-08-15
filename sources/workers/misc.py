from pathlib import PurePath


def convert_request_files(files):
	return list(filter(None, map(convert_request_file, files)))


def convert_request_file(file):
	logger.info('convert_request_file: %s' % file)

	if file.endswith('/custom_job_metadata.json'):
		return None # effectively hide the file from further processing
	if file.lower().endswith('.xlsx'):
		converted = PurePath('/'.join(file.parts[:-1] + ('converted', file.parts[-1] + '.n3')))
		convert_excel_to_rdf(file, converted)
		return converted
	else:
		return file


def convert_excel_to_rdf(uploaded, to_be_processed):
	"""run a POST request to csharp-services to convert the file"""
	logger.info('xlsx_to_rdf: %s' % uploaded)
	requests.post(os.environ['CSHARP_SERVICES_URL'] + '/xlsx_to_rdf', json={"root": "ic_ui:investment_calculator_sheets", "input_fn": uploaded, "output_fn": to_be_processed}).raise_for_status()


