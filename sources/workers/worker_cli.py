#!/usr/bin/env python3

import sys, os, shlex

import fire

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))



class Cli:
	def __init__(self):
		pass

	"""
	We have two main ways of invoking prolog:
		1. "RPC" - we send a json request to a server, and get a json response back - or at least it could be a server. 
		In practice, the overhead of launching swipl (twice when debugging) is minimal, so we just launch it for each request.
		( - a proper tcp (http?) server plumbing for our RPC was never written or needed yet).
		
		There are also two ways to pass the goal to swipl, either it's passed on the command line, or it's sent to stdin.
		The stdin method causes problems when the toplevel breaks on an exception, so it's not used, but a bit of the code
		might get reused now, because we will again be generating a goal string that can be copy&pasted into swipl.
	
	"""

	def prepare_calculation(self, input_directory):
		"""
		* optional conversion from xlsx to rdf
		* creation of final_result directory
		* creation of result_directory
		* last_result symlink
		* read worker_config_json
		* assemble goal for swipl
		"""


		return result_directory



	def local_rpc(self):
		pass


	def local_calculator(self):
		pass


	def trigger_rpc(self):
		pass


	def trigger_calculator(self):
		pass



	def run_last_request_outside_of_docker(self):
		"""
		you should run this script from server_root/

		you should also have `services` running on the host (it doesnt matter that it's simultaneously running in docker), because they have to access files by the paths that `workers` sends them.
		"""
		tmp_volume_data_path = '/var/lib/docker/volumes/robust_tmp/_data/'
		os.system('sudo chmod -R o+rX '+tmp_volume_data_path)
		last_request_host_path = tmp_volume_data_path + os.path.split(os.readlink(tmp_volume_data_path+'last_request'))[-1]

		self.local_calculator(self.prepare_calculation(last_request_host_path))



if __name__ == "__main__":
	fire.Fire(Cli)
