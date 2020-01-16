#!/usr/bin/env sh

crond
sh /app/src/generate_nginx_config.sh
nginx -g 'daemon off;'
