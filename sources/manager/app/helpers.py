import os
import shutil
from pathlib import PurePath

from tmp_dir_path import get_tmp_directory_absolute_path, git


def make_converted_dir(file):
	converted_dir = PurePath('/'.join(PurePath(file).parts[:-1] + ('converted',)))
	os.makedirs(converted_dir, exist_ok=True)
	return converted_dir



		


def copy_repo_status_txt_to_result_dir(result_tmp_path):
	shutil.copyfile(
		os.path.abspath(git('sources/static/git_info.txt')),
		os.path.join(result_tmp_path, 'git_info.txt'))


