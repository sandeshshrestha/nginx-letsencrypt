#!/usr/bin/env sh

URL=$1
PROXY=$2
EXTRA_CONFIG=$3

echo "
server {
	listen 80;
	server_name $URL;
	return 301 https://\$host\$request_uri;
}

server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;
	server_name $URL;

	location /.well-known {
		auth_basic off;
		alias /var/www/$URL/.well-known;
	}

	error_log /var/log/nginx/$URL.error.log crit;

	location / {
    proxy_redirect   off;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
		proxy_pass       $PROXY;
    proxy_buffering    off;
    proxy_buffer_size  128k;
    proxy_buffers 100  128k;

    location ~* \.(?:ico|css|js|gif|jpe?g|png)$ {
      expires 120d;
      add_header Pragma public;
      add_header Cache-Control \"public\";
      proxy_redirect   off;
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_pass       $PROXY;
    }
	}

	chunked_transfer_encoding on;

	ssl_certificate      /etc/letsencrypt/live/$URL/fullchain.pem;
	ssl_certificate_key  /etc/letsencrypt/live/$URL/privkey.pem;
	ssl_session_timeout 1d;
	ssl_session_cache shared:SSL:50m;
	ssl_session_tickets off;

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
	ssl_prefer_server_ciphers on;

	add_header Strict-Transport-Security max-age=15768000;

	ssl_stapling on;
	ssl_stapling_verify on;

	ssl_trusted_certificate /etc/letsencrypt/live/$URL/fullchain.pem;

	resolver 1.1.1.1 valid=300s;
	resolver_timeout 5s;

	$EXTRA_CONFIG
}
"
