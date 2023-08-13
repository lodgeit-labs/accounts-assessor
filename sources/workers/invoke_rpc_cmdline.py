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
@click.option('-de', '--debug_call_prolog', type=bool, default=True)
@click.option('-dr', '--dry_run', type=bool, default=False, help="stop before invoking swipl")

def run(debug_loading, debug, request_files: list[str], dev_runner_options, prolog_flags, server_url, halt,
		pipe_rpc_json_to_swipl_stdin, debug_call_prolog, dry_run):


	# get absolute paths of request files, given directories and stuff

	files2 = get_absolute_paths(request_files)
	files3 = flatten_file_list_with_dirs_into_file_list(files2)
	request_tmp_directory_name, request_tmp_directory_absolute_path = create_tmp()
	copy_request_files_to_tmp(request_tmp_directory_absolute_path, files3)





	# dev_runner_options. Not sure what semantics we'd want for passing configuration options down the stack, possibly things like this should be a config.json option, and overridable by that key on the command line., and as kwargs?
	if dev_runner_options == None:
		dev_runner_options = ''


	# set up logging. again, this could be a worker config
	if debug_call_prolog:
		# is the name right?
		invoke_rpc_logger = logging.getLogger('invoke_rpc')
		# logger.addHandler(logging.StreamHandler())
		# i suppose this will be overriden by root logger level?
		invoke_rpc_logger.setLevel(logging.DEBUG)



	# request_format is a bit of a legacy thing.
	request_format = 'xml'
	for f in files3:
		if any([f.lower().endswith(x) for x in ['n3', 'trig']]):
			request_format = 'rdf'



	print(call_prolog_calculator.create_calculator_job(
		server_url=server_url,
		request_tmp_directory_name=request_tmp_directory_name,
		request_files=files3,
		dev_runner_options=shlex.split(dev_runner_options),
		prolog_flags=prolog_flags,
		pipe_rpc_json_to_swipl_stdin=pipe_rpc_json_to_swipl_stdin,
		debug_loading=debug_loading,
		debug=debug,
		halt=halt,
		request_format = request_format,
		dry_run=dry_run
	).message_id)

if __name__ == '__main__':
	run()


