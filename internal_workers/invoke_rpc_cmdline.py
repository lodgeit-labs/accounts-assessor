#!/usr/bin/env python3

import click, shlex
from tmp_dir_path import *
from invoke_rpc import *
from fs_utils import get_absolute_paths, flatten_file_list_with_dirs_into_file_list

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
	files2 = get_absolute_paths(request_files)
	files3 = flatten_file_list_with_dirs_into_file_list(files2)
	request_tmp_directory_name, request_tmp_directory_absolute_path = create_tmp()
	copy_request_files_to_tmp(request_tmp_directory_absolute_path, files3)
	call_prolog_calculator(server_url, request_tmp_directory_name, files3,  dev_runner_options=shlex.split(dev_runner_options), prolog_flags=prolog_flags, debug_loading=debug_loading, debug=debug, halt=halt, use_celery=False)

if __name__ == '__main__':
	run()


