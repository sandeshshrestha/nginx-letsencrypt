#!/usr/bin/env python

import os
import json
import requests
from getBasic import getBasic
from getExtended import getExtended

certbot_args = os.environ.get('CERTBOT_ARGS')
inputFile = "/app/config/nginx.json"
dir_path = os.path.dirname(os.path.realpath(__file__))
outputFile = '/etc/nginx/conf.d/nginx-letsencrypt.conf'

if certbot_args is None:
	certbot_args = ''
print('- Checking if nginx is already running')
os.system("service nginx status")

f = open(inputFile, 'r')
sites = json.load(f)
f.close()

print('\n\n- Received following configs')
print(json.dumps(sites, indent=4))

# if file is not there we are running it for the first time.
# So We need to create basic config for all site where all http points to its respective proxy
# It will be required while authenticating with certbot
if os.path.isfile(outputFile):
	print('- Initial config found.')
else:
	# Generate basic nginx config
	print('\n\n- Initial config not found. (Creating)')
	config = ''
	for site in sites:
		url = site['url']

		os.makedirs("/var/www/%s/.well-known" % (url))
		config = config + getBasic(site)

	# Save the generated config into file
	print('- Created following initial config')
	print(outputFile)
	print(config)
	file = open(outputFile, 'w')
	file.write(config)
	file.close()

# Start nginx server so at least all http proxy are working
os.system("service nginx start")

# Generate ssl certificate and change nginx conig
config = '';
for site in sites:
	proxy = site['proxy']
	url = site['url']
	email = site['email']

	https = False
	if 'https' in site:
		https = site['https']
	print('\n\n- Processing %s -> %s' % (url, proxy))


	if https:
		# If Certificate exists we assume that it is already created so we just create nginx config for this site
		if os.path.isfile("/etc/letsencrypt/live/%s/fullchain.pem" % (url)):
			print('- Certificate already exists for %s' % (url))
			config = config + getExtended(site)
		else:
			# Proxy Reachable
			print('- Creating new certificate for %s' % (url))

			if os.system("certbot certonly --webroot -w /var/www/%s -d %s -m %s --agree-tos %s" % (url, url, email, certbot_args)) == 0:
				print("- Created certificate for %s" % (url))
				config = config + getExtended(site)
			else:
				print("- Failed to create certificate for %s" % (url))
				config = config + getBasic(site)
	else:
		config = config + getBasic(site)

print('\n\n- Writing final config file')
print(outputFile)
print(config)
file = open(outputFile, 'w')
file.write(config)
file.close()

# Stop nginx
os.system("service nginx stop")
