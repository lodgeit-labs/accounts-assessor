from c import app

from invoke_rpc_cmdline import *

call_prolog2=app.task(call_prolog)

def call_prolog(*args, **kwargs):
	return call_prolog2.apply_async(args, kwargs).get()


