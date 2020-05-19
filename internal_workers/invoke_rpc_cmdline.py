#!/usr/bin/env python3

import time, click, shlex,
from tmp_dir_path import *
from invoke_rpc import *
from atomic_integer import AtomicInteger


server_started_time = time.time() # in theory, this could collide, fixme
client_request_id = AtomicInteger()



@click.command()
@click.argument('request_files', nargs=-1)
@click.option('-d', '--dev_runner_options', type=str)
@click.option('-p', '--prolog_flags', type=str)
@click.option('-s', '--server_url', type=str, default='http://localhost:7778')
@click.option('-dbgl', '--debug_loading', type=bool, default=False)
@click.option('-dbg', '--debug', type=bool, default=False)
@click.option('-hlt', '--halt', type=bool, default=True)

def run(debug_loading, debug, request_files, dev_runner_options, prolog_flags, server_url, halt):

	if dev_runner_options == None:
		dev_runner_options = ''

	tmp_directory_name, tmp_directory_absolute_path = create_tmp()
	request_files2 = get_absolute_paths(request_files)
	files = flatten_file_list_with_dirs_into_file_list(request_files)
	copy_request_files_to_tmp(tmp_directory_absolute_path, files)

	msg = {
		"method": "calculator",
		"params": {
			"server_url": server_url,
			"tmp_directory_name": tmp_directory_name,
			"request_files": files2}
	}
	call_prolog(msg=msg, dev_runner_options=shlex.split(dev_runner_options), prolog_flags=prolog_flags, debug_loading=debug_loading, debug=debug, halt=halt)




if __name__ == '__main__':
	run()


