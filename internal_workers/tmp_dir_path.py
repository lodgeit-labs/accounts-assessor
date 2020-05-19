
def git(Suffix = ""):
	""" get git repo root path """
	here = os.path.dirname(__file__)
	r = os.path.normpath(os.path.join(here, '../', Suffix))
	return r

def create_tmp_directory_name():
	""" create a unique name """
	return str(server_started_time) + '.' + str(client_request_id.inc())

def get_tmp_directory_absolute_path(name):
	""" append the unique name to tmp/ path """
	return os.path.abspath(os.path.join(git('server_root/tmp'), name))

def create_tmp():
	name = create_tmp_directory_name()
	full_path = os.path.normpath(get_tmp_directory_absolute_path(name))
	os.mkdir(path)
	return name,full_path

def copy_request_files_to_tmp(tmp_directory_absolute_path, files)
	# request file paths, as passed to prolog
	files2 = []
	for f in files:
		# create new path where request file will be copied, copy it
		tmp_fn = os.path.abspath('/'.join([tmp_directory_absolute_path, ntpath.basename(f)]))
		shutil.copyfile(f,tmp_fn)
		files2.append(tmp_fn)
	return files2


