import pytest

import requests


def test_manager_ipv6():
	""" test manager ipv6 http"""
	manager_url = 'http://[::1]:9111'
	try:
		requests.get(manager_url + '/health')
	except requests.exceptions.RequestException:
		pytest.fail(msg='Connection error', pytrace=False)

