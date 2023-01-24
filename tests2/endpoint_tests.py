#!/usr/bin/env python3

import fire
import glob

class Runner():
    def start_endpoint_tests(self, robust_server_url: str):
        """
        1) enumerate testcases
        2) store an endpoint_tests job
        3) run a worker

        """

        print('testing ' + robust_server_url)

        dirs = glob.glob('endpoint_tests/*/*/')
        dirs.sort()
        for dir in dirs:
            print(dir)





if __name__ == "__main__":
	fire.Fire(Runner) # pragma: no cover
