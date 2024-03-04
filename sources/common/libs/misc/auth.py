import re

from pathlib import Path as P




def write_htaccess(user, path):

	#i think we'll eventually replace the role of apache here, with python.
	#https://stackoverflow.com/questions/71276790/list-files-from-a-static-folder-in-fastapi

	with open(P(path) / '.access', 'w') as f:
		f.write(f"""{user}\n""")

	if user != 'nobody':
	
		if user.endswith('@basicauth'):
			user = user[:-len('@basicauth')]
	
			user = re.escape(user)
			with open(P(path) / '.htaccess', 'w') as f:
				f.write(f"""
RewriteEngine On
SetEnvIf Caddybasicauthuser "^{user}$" Caddybasicauthuser
Require env Caddybasicauthuser
""")

		else:
			user = re.escape(user)
			with open(P(path) / '.htaccess', 'w') as f:
				f.write(f"""
RewriteEngine On
SetEnvIf X-Forwarded-User "^{user}$" OauthUser
Require env OauthUser
""")
