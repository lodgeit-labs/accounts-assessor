from pathlib import Path as P
import time, shutil, ntpath, os, re
import sys, subprocess
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common/libs/misc')))


def git(suffix = ""):
	""" get git repo root path """
	here = os.path.dirname(__file__)
	r = os.path.normpath(os.path.join(here, '../../', suffix))
	return r


def sources(suffix=""):
	return os.path.normpath(os.path.join(git(), 'sources/', suffix))



def ln(target, source):
	xxx1 = ['/bin/ln', '-s', target, source]
	subprocess.call(xxx1)


def symlink(name, tmp_directory_name):
	""" first create a symlink safely in our own directory, and then move it to the right place. """
	symlink_path = get_tmp_directory_absolute_path(tmp_directory_name) + '/' + name
	subprocess.call([
		'/bin/ln', '-s',
		tmp_directory_name,
		symlink_path
	])
	os.rename(symlink_path,	get_tmp_directory_absolute_path(name))


def get_tmp_directory_absolute_path(name):
	""" append the unique name to tmp/ path """
	return os.path.normpath(os.path.abspath(os.path.join(git('server_root/tmp'), name)))

