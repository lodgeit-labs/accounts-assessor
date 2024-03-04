from fastapi import Request
import logging


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

ch = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)



"""
the header that Caddy sends is CaddyBasicAuthUser, configured in Caddyfile.
the header that oauth2-proxy sends are X-Forwarded-Email etc.

"""

def get_user(request: Request):

	# get user from header coming from oauth2-proxy
	authorization = request.headers.get('X-Forwarded-Email', None)
	logger.info('X-Forwarded-Email: %s' % authorization)
	authorization = request.headers.get('X-Forwarded-User', None)
	logger.info('X-Forwarded-User: %s' % authorization)
	if authorization is not None:
		return authorization

	# get user from header coming from caddy
	authorization = request.headers.get('CaddyBasicAuthUser', None)
	logger.info('CaddyBasicAuthUser: %s' % authorization)
	if authorization is not None:
		return authorization + '@basicauth'

	return 'nobody'

