#!/usr/bin/env python3

import threading, json, time, click, subprocess, shlex, shutil, ntpath, os



class AtomicInteger():
	""" https://stackoverflow.com/questions/23547604/python-counter-atomic-increment """
	def __init__(self, value=0):
		self._value = value
		self._lock = threading.Lock()

	def inc(self):
		with self._lock:
			self._value += 1
			return self._value

	def dec(self):
		with self._lock:
			self._value -= 1
			return self._value


	@property
	def value(self):
		with self._lock:
			return self._value

	@value.setter
	def value(self, v):
		with self._lock:
			self._value = v
			return self._value




server_started_time = time.time()
client_request_id = AtomicInteger()




def git(Suffix = ""):
	here = os.path.dirname(__file__)
	#print(here)
	r = os.path.normpath(os.path.join(here, '../../', Suffix))
	#print(r)
	return r




def files_in_dir(dir):
	result = []
	for filename in os.listdir(dir):
		filename2 = '/'.join([dir, filename])
		if os.path.isfile(filename2):
			result.append(filename2)
	return result

@click.command()
@click.argument('request_files', nargs=-1)
@click.option('-dro', '--dev_runner_options', type=str)
def run(request_files, dev_runner_options):
	if dev_runner_options == None:
		dev_runner_options = ''
	server_url = 'http://localhost:8080'
	request_files = [os.path.abspath(f) for f in request_files]
	tmp_directory_name, tmp_directory_absolute_path = create_tmp()
	files = request_files
	if len(request_files) == 1:
		f = request_files[0]
		if not os.path.isfile(f):
			files = files_in_dir(f)
	files2 = []
	for f in files:
		tmp_fn = os.path.abspath('/'.join([tmp_directory_absolute_path, ntpath.basename(f)]))
		shutil.copyfile(f,tmp_fn)
		files2.append(tmp_fn)
	msg = {
		"method": "calculator",
		"params": {
			"server_url": server_url,
			"tmp_directory_name": tmp_directory_name,
			"request_files": files2}
	}
	call_rpc(msg=msg, dev_runner_options=shlex.split(dev_runner_options))

def call_rpc(msg, dev_runner_options=[], prolog_flags='true'):
	os.chdir(git("server_root"))
	cmd0 = ['swipl', '-s', git("lib/dev_runner.pl"),'--problem_lines_whitelist',git("misc/problem_lines_whitelist"),"-s", git("lib/debug_rpc.pl")]
	cmd1 = dev_runner_options
	cmd2 = ['-g', prolog_flags + ',lib:process_request_rpc_cmdline']
	cmd = cmd0 + cmd1 + cmd2
	print(' '.join(cmd))
	input = json.dumps(msg)
	print(input)
	if os.path.expanduser('~') == '/var/www':
		#os.environ.putenv('SWI_HOME_DIR', git('../.local/share/swi-prolog/'))
		os.environ.putenv('SWI_HOME_DIR', '/home/apache/swi-prolog')
	#p = subprocess.Popen(['bash', '-c', 'export'], universal_newlines=True)
	#p.communicate()
	p = subprocess.Popen(cmd, universal_newlines=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
	(stdout_data, stderr_data) = p.communicate(input = input)
	print("result from prolog:")
	print(stdout_data)
	print("end of result from prolog.")
	try:
		return json.loads(stdout_data)
	except json.decoder.JSONDecodeError as e:
		print(repr(e))
		raise e
		#raise(Exception(repr(e)))
		#import IPython; IPython.embed()


def create_tmp_directory_name():
	return str(server_started_time) + '.' + str(client_request_id.inc())



def get_tmp_directory_absolute_path(name):
	return os.path.join(git('server_root/tmp'), name)
	
def create_tmp():
	name = create_tmp_directory_name()
	path = get_tmp_directory_absolute_path(name)
	os.mkdir(path)
	subprocess.call(['/bin/rm', get_tmp_directory_absolute_path('last')])
	subprocess.call(['/bin/ln', '-s', get_tmp_directory_absolute_path(name), get_tmp_directory_absolute_path('last')])
	return name,path



if __name__ == '__main__':
	run()


