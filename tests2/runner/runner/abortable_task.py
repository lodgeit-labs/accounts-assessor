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

