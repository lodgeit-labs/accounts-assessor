"""
general-purpose filesystem utilities
"""
import os.path, sys
from os import listdir
from os.path import isfile, join
import ntpath
import shlex

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

def save_django_form_uploaded_file(tmp_directory_path, idx, f):
	tmp_fn = os.path.abspath('/'.join([tmp_directory_path, ntpath.basename(str(idx))]))
	with open(tmp_fn, 'w') as destination:
		destination.write(f)
	return tmp_fn

def command_nice(lst):
	out = ''
	for idx, i in enumerate(lst):
		if idx != 0:
			out += "  "
		if isinstance(i, list):
			out += (' '.join([shlex.quote(str(j)) for j in i]))
		else:
			out += shlex.quote((str(i)))
		if idx != len(lst) - 1:
			out += (' \\')
		out += ('\n')

def flatten_lists(x):
	if isinstance(x, list):
		r = []
		for y in x:
			z = flatten_lists(y)
			if isinstance(z, list):
				r += z
			else:
				r.append(z)
		return r
	else:
		return x


#def env_or(json, key):
	#print(key, '=', os.environ.get(key), ' or ', json.get(key))
#	return os.environ.get(key) or json.get(key)

