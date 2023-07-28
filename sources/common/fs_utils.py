"""
general-purpose filesystem utilities
"""
import glob
import os.path, sys
import pathlib
from os import listdir, makedirs
from os.path import isfile, join
import ntpath
import shlex
from pathlib import Path as P

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


def find_report_by_key(reports, name):
	for i in reports:
		if i['key'] == name:
			return i['val']['url']


def robust_testcase_dirs(suite='.', dirglob=''):
	dirs0 = [pathlib.Path(x) for x in sorted(glob.glob(root_dir=suite, pathname='**/' + dirglob, recursive=True))]
	# filterr out 'responses' dirs
	#dirs1 = list(filter(lambda x: x.name != 'responses', dirs0))
	# fitler out non-leaf dirs
	#dirs2 = list(filter(lambda x: x not in [y.parent for y in dirs1], dirs1))

	for d in dirs0:
		if glob.glob(root_dir=suite, pathname=str(d) + '/request/*') != []:
			yield d
	#return dirs2



# def dirs_fixup():
# 	"""walk testcase dirs and do some stuff"""
# 	suite = P('../../tests2/endpoint_tests/')
# 	for d in robust_testcase_dirs(suite):
# 		print(f'testcase:{d}')
# 		newdir = str(suite / d / 'request')
# 		print(f'newdir: {newdir}')
# 		makedirs(newdir, exist_ok=True)
# 		for file in listfiles(suite / d):
# 			print(f'request file:{file}')
# 			tgt = str(suite / d / 'request' / os.path.basename(file))
# 			print(f'tgt:{tgt}')
# 			os.rename(file, tgt)


def listfiles(path) -> P:
	for f in glob.glob(str(path) + '/*'):
		f = P(f)
		if not f.is_dir():
			yield f
