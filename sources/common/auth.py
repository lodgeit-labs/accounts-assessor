import re
import base64
from fastapi import Request
from pathlib import Path as P
import logging
logger = logging.getLogger(__name__)



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



def write_htaccess(user, path):

	#i think we'll eventually replace the role of apache here, with python.
	#https://stackoverflow.com/questions/71276790/list-files-from-a-static-folder-in-fastapi

	with open(P(path) / '.access', 'w') as f:
		f.write(f"""{user}\n""")

	if user != 'nobody':
		user = re.escape(user)
		with open(P(path) / '.htaccess', 'w') as f:
			f.write(f"""

RewriteEngine On

SetEnvIf CaddyBasicAuthUser "^{user}$" CaddyBasicAuthUser=$1
Allow from env=CaddyBasicAuthUser

SetEnvIf X-Forwarded-User "^{user}$" OauthUser=$1
Allow from env=OauthUser

Deny from all

""")




# """
# # Authorization: Basic <base64-encoded username:password>
# authorization = request.headers.get('Authorization', None)
# logger.info('Authorization: %s' % authorization)
# if authorization is not None:
# 	authorization = authorization.split(' ')
# 	if len(authorization) == 2 and authorization[0] == 'Basic':
# 		logger.info('authorization: %s' % authorization)
# 		token = base64.b64decode(authorization[1]).decode()
# 		token = token.split(':')
# 		if len(token) == 2:
# 			return token[0]# + '@basicauth'
# """
