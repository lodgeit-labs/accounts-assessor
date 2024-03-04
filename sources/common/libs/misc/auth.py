import re

from pathlib import Path as P




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

SetEnvIf Caddybasicauthuser "^{user}$" Caddybasicauthuser=$1
Allow from env=Caddybasicauthuser

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
