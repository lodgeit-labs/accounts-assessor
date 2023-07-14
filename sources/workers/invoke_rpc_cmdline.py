#!/usr/bin/env python3

import sys, os
import click, shlex
sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../common')))
from tmp_dir_path import *
from invoke_rpc import *
from fs_utils import get_absolute_paths, flatten_file_list_with_dirs_into_file_list
import call_prolog_calculator


@click.command()
@click.argument('request_files', nargs=-1)
@click.option('-d', '--dev_runner_options', type=str)
@click.option('-p', '--prolog_flags', type=str, default='true')
@click.option('-s', '--server_url', type=str, default='http://localhost:7778')
@click.option('-dbgl', '--debug_loading', type=bool, default=False)
@click.option('-dbg', '--debug', type=bool, default=True)
@click.option('-hlt', '--halt', type=bool, default=True)
@click.option('-pc', '--pipe_rpc_json_to_swipl_stdin', type=bool, default=False)
@click.option('-debug_call_prolog', '--debug_call_prolog', type=bool, default=True)
def run(debug_loading, debug, request_files, dev_runner_options, prolog_flags, server_url, halt,
		pipe_rpc_json_to_swipl_stdin, debug_call_prolog):

	if debug_call_prolog:
		# is the name right?
		invoke_rpc_logger = logging.getLogger('invoke_rpc')
		# logger.addHandler(logging.StreamHandler())
		# i suppose this will be overriden by root logger level?
		invoke_rpc_logger.setLevel(logging.DEBUG)
	if dev_runner_options == None:
		dev_runner_options = ''
	files2 = get_absolute_paths(request_files)
	files3 = flatten_file_list_with_dirs_into_file_list(files2)
	request_format = 'xml'
	for f in files3:
		if any([f.lower().endswith(x) for x in ['n3', 'trig']]):
			request_format = 'rdf'
	request_tmp_directory_name, request_tmp_directory_absolute_path = create_tmp()
	copy_request_files_to_tmp(request_tmp_directory_absolute_path, files3)
	final_result_tmp_directory_name, final_result_tmp_directory_path = create_tmp()
	call_prolog_calculator.call_prolog_calculator(
		server_url=server_url,
		request_tmp_directory_name=request_tmp_directory_name,
		request_files=files3,
		dev_runner_options=shlex.split(dev_runner_options),
		prolog_flags=prolog_flags,
		pipe_rpc_json_to_swipl_stdin=pipe_rpc_json_to_swipl_stdin,
		debug_loading=debug_loading,
		debug=debug,
		halt=halt,
		final_result_tmp_directory_name=final_result_tmp_directory_name,
		final_result_tmp_directory_path=final_result_tmp_directory_path,
		request_format = request_format
	)

if __name__ == '__main__':
	run()


