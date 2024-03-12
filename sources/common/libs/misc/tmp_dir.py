import time,os,datetime
import agraph
from atomic_integer import AtomicInteger
server_started_time = time.time()
client_request_id = AtomicInteger()
from auth import write_htaccess
from tmp_dir_path import get_tmp_directory_absolute_path


def get_unique_id():
	"""
	https://github.com/lodgeit-labs/accounts-assessor/issues/25
	"""
	return str(agraph.agc().createBNode().getId()[2:])


def create_tmp_directory_name():
	""" create a unique name """
	return '.'.join([
		'UTC' + datetime.datetime.utcnow().strftime('%Y_%m_%d__%H_%M_%S'),
		str(os.getpid()),
		str(client_request_id.inc()),
		get_unique_id()])


def create_tmp(name=None, exist_ok=False):
	if name is None:
		name = create_tmp_directory_name()
	full_path = get_tmp_directory_absolute_path(name)
	os.makedirs(full_path, exist_ok=exist_ok)
	return name, full_path


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


