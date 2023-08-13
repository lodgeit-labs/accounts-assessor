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

	def prepare_calculation(self):
		


if __name__ == "__main__":
	fire.Fire(Cli)
