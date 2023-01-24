#!/usr/bin/env python3

import fire
import glob


def start_endpoint_tests(robust_server_url: str):

    dirs = glob.glob('endpoint_tests/ledger/*')

