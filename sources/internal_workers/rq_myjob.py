import rq

class MyJob(rq.job.Job):
	def get_result_ttl(self, default_ttl=None):
		return 60*60*24*7 if self.result_ttl is None else self.result_ttl

