import datetime
import time
import luigi


class AbortableTask(luigi.Task):
	accepts_messages = True
	should_die = False

	ts = luigi.Parameter('_')

	def proces_msgs(self):
		if not self.scheduler_messages.empty():
			self.process_msg(self.scheduler_messages.get())

	def process_msg(self, msg):
		print(msg)
		if msg.content == "die":
			self.should_die = True
			msg.respond("okay")
		else:
			msg.respond("unknown message")

	def check_die(self):
		self.proces_msgs()
		return self.should_die

	def run(self):
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		print('sleep 20s..');time.sleep(20)
		if self.check_die(): return
		self.output().open('w').close()

	def output(self):
		return luigi.LocalTarget('/tmp/bar/%s' % (self.ts))



class ImmediateComputation(luigi.Task):
	test = luigi.parameter.DictParameter()


	def run(self):
		inputs = self.copy_inputs()
		self.run_request(inputs)


	def copy_inputs(self):
		request_files_dir: pathlib.Path = P(self.test['path']) / 'inputs'
		request_files_dir.mkdir(parents=True)
		files = []
		input_file: pathlib.Path
		for input_file in sorted(filter(lambda x: not x.is_dir(), (P(self.test['suite']) / self.test['dir']).glob('*'))):
			shutil.copyfile(input_file, request_files_dir / input_file.name)
			files.append(request_files_dir / input_file.name)
		return files


	def run_request(self, inputs):
		url = self.test['robust_server_url']
		logging.getLogger('robust').debug('')
		logging.getLogger('robust').debug('querying ' + url)


		requests.post(
				url + '/upload',
				files={'file1':open(inputs[0])}
		)

		# time.sleep(10)
		# logging.getLogger('robust').debug('...')
		# time.sleep(10)
		# logging.getLogger('robust').debug('...')


		o = self.output()
		P(o.path).mkdir(parents=True)
		with open(P(o.path) / 'result.xml', 'w') as r:
			r.write('rrrr')


	def output(self):
		return luigi.LocalTarget(P(self.test['path']) / 'outputs')








--


#reports = self.reportlist_from_saved_responses_directory(results.path)
def reportlist_from_saved_responses_directory(self, path):
	return [{'fn' : f} for f in P(path).glob('*')]


