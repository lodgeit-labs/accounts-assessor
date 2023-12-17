from pathlib import Path as P
import time, shutil, ntpath, os, re
import sys, subprocess
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
import agraph
from atomic_integer import AtomicInteger
server_started_time = time.time()
client_request_id = AtomicInteger()
from auth import write_htaccess


def git(Suffix = ""):
	""" get git repo root path """
	here = os.path.dirname(__file__)
	r = os.path.normpath(os.path.join(here, '../../', Suffix))
	return r


def sources(Suffix=""):
	return os.path.normpath(os.path.join(git(), 'sources/', Suffix))



def get_unique_id():
	"""
	https://github.com/lodgeit-labs/accounts-assessor/issues/25
	"""
	return str(agraph.agc().createBNode().getId()[2:])


def create_tmp_directory_name():
	""" create a unique name """
	return '.'.join([
		str(server_started_time),
		str(os.getpid()),
		str(client_request_id.inc()),
		get_unique_id()])

def get_tmp_directory_absolute_path(name):
	""" append the unique name to tmp/ path """
	return os.path.normpath(os.path.abspath(os.path.join(git('server_root/tmp'), name)))

def create_tmp():
	name = create_tmp_directory_name()
	full_path = get_tmp_directory_absolute_path(name)
	os.mkdir(full_path)
	return name,full_path

def create_tmp_for_user(user):
	name, path = create_tmp()
	write_htaccess(user, path)
	return name, path



def copy_request_files_to_tmp(tmp_directory_absolute_path, files):
	# request file paths, as passed to prolog
	files2 = []
	for f in files:
		# create new path where request file will be copied, copy it
		tmp_fn = os.path.abspath('/'.join([tmp_directory_absolute_path, ntpath.basename(f)]))
		shutil.copyfile(f,tmp_fn)
		files2.append(tmp_fn)
	return files2

def ln(target, source):
	xxx1 = ['/bin/ln', '-s', target, source]
	subprocess.call(xxx1)


def update_last_request_symlink(request_tmp_directory_name):
	""" first create a symlink safely in our own directory, and then move it to the right place. """
	symlink_path = get_tmp_directory_absolute_path(request_tmp_directory_name) + '/last_request'
	subprocess.call([
		'/bin/ln', '-s',
		request_tmp_directory_name,
		symlink_path
	])
	os.rename(symlink_path,	get_tmp_directory_absolute_path('last_request'))
