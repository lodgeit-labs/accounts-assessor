import os
import shutil
from pathlib import PurePath

from tmp_dir_path import get_tmp_directory_absolute_path


def make_converted_dir(file):
	converted_dir = PurePath('/'.join(PurePath(file).parts[:-1] + ('converted',)))
	os.makedirs(converted_dir, exist_ok=True)
	return converted_dir



def guess_request_format_rdf_or_xml(params):
	if params.get('request_format') is None:
		if len(params['request_files']) == 1 and params['request_files'][0].lower().endswith('.xml'):
			return 'xml'
		else:
			return 'rdf'
	else:
		return params['request_format']
		


def copy_repo_status_txt_to_result_dir(result_tmp_path):
	shutil.copyfile(
		os.path.abspath(git('sources/static/git_info.txt')),
		os.path.join(result_tmp_path, 'git_info.txt'))


