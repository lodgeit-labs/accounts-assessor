"""
general-purpose filesystem utilities
"""
import os.path
from os import listdir
from os.path import isfile, join
import ntpath

def files_in_dir(dir):
	result = []
	for filename in os.listdir(dir):
		filename2 = '/'.join([dir, filename])
		if os.path.isfile(filename2):
			result.append(filename2)
	return result

def get_absolute_paths(request_files):
	return [os.path.abspath(os.path.expanduser(f)) for f in request_files]

def flatten_file_list_with_dirs_into_file_list(paths):
	files = []
	for path in paths:
		if os.path.isdir(path):
			files.extend(files_in_dir(path))
		elif os.path.isfile(path):
			files.append(path)
		else:
			raise Exception('file not found: {0}'.format(path))
	return files

def directory_files(directory):
	return [f for f in listdir(directory) if isfile(join(directory, f))]

def save_django_uploaded_file(tmp_directory_path, f):
	tmp_fn = os.path.abspath('/'.join([tmp_directory_path, ntpath.basename(f.name)]))
	with open(tmp_fn, 'wb+') as destination:
		for chunk in f.chunks():
			destination.write(chunk)
	return tmp_fn

