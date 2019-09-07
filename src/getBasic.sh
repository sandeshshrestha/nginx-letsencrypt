#!/usr/bin/env sh

URL=$1
PROXY=$2

echo "
server {
	listen 80;
	server_name $URL;
	client_max_body_size 10G;

	location /.well-known {
		auth_basic off;
		alias /var/www/$URL/.well-known;
	}

	access_log /var/log/nginx/$URL.access.log;
	error_log /var/log/nginx/$URL.error.log;

	location / {
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;
		proxy_pass $PROXY;
	}
}
";
