#!/usr/bin/env python3


import fire
import worker
if __name__ == "__main__":
	worker.local_calculator = worker.local_calculator.fn
	worker.local_rpc = worker.local_rpc.fn
	fire.Fire(worker)


