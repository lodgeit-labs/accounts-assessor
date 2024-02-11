import os
import psutil

def get_unused_cpu_cores(threshold=10, interval=5):
	"""
	Get a list of CPU cores considered unused based on a usage threshold.

	:param threshold: Usage percentage below which a core is considered unused.
	:param interval: Time in seconds over which to average CPU usage.
	:return: List of CPU core indices considered unused.
	"""
	total_cores = os.cpu_count()
	# Get CPU usage per core
	cpu_usage_per_core = psutil.cpu_percent(interval=interval, percpu=True)
	unused_cores = [index for index, usage in enumerate(cpu_usage_per_core) if usage < threshold]

	return unused_cores

if __name__ == "__main__":

	unused_cores = get_unused_cpu_cores()
	print(f"Unused CPU Cores (Usage Threshold < 10%): {unused_cores}")

