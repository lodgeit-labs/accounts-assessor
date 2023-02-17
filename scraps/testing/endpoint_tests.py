#!/usr/bin/env python3

"""

Given that tasks can be expected to run for days, it doesn't matter that agraph doesn't support transactions, we'll have to do some task brokering in our workers.



task queue issues in general:
    oom
        is there a child process that can be killed
        is the worker killed or is the child process killed
        are there options to redo failed tasks

"""



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
