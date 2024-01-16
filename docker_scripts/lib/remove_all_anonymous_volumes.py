#!/usr/bin/env python3

import docker, re

def remove_anonymous_volumes():
	client = docker.from_env()

	# Fetch all volumes
	volumes = client.volumes.list()

	for volume in volumes:

		volume_info = volume.attrs

		if not 'Labels' in volume_info or volume_info['Labels'] is None:
			if not 'Name' in volume_info or re.findall(r"([a-f\d]{64})", volume_info['Name']):
				print(f"Removing anonymous volume: {volume.name}")
				try:
					volume.remove()
				except Exception as e:
					print(f"An error occurred: {e}")

if __name__ == "__main__":
	remove_anonymous_volumes()
