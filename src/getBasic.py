#!/usr/bin/env python

def getBasic( site ):
	url = site['url']
	proxy = site['proxy']
	return """
server {
	listen 80;
	server_name %s;
	client_max_body_size 10G;

	location /.well-known {
		auth_basic off;
		alias /var/www/%s/.well-known;
	}

	access_log /var/log/nginx/%s.access.log;
	error_log /var/log/nginx/%s.error.log;

	location / {
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
		proxy_pass %s;
	}
}
""" % (url, url, url, url, proxy)
