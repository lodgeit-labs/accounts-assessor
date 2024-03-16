#!/usr/bin/env python3
import logging
import pathlib
import shutil
import fire
import json
import sys
import os

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), '../lib')))
import common




logger = logging.getLogger(__name__)




def run(session='~/robust_tests/latest'):
	dir = pathlib.Path(os.path.expanduser(session))

	summary = dir / 'summary.json'
	with open(summary) as f:
		j = json.load(f)

	bad = j['bad']
	logger.info(f'bad: {len(bad)=}')
	
	common.print_summary_summary(j)


if __name__ == '__main__':
	fire.Fire(run)
