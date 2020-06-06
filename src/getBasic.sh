#!/usr/bin/env sh

URL=$1
PROXY=$2

echo "
server {
	listen               80;
	server_name          $URL;

	location /.well-known {
		auth_basic off;
		alias      /var/www/$URL/.well-known;
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
}
";
