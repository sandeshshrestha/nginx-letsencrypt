#!/usr/bin/env sh

sh /app/src/generate_nginx_config.sh
nginx -g 'daemon off;'
