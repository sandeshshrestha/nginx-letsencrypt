#!/usr/bin/env bash

python /app/src/generate_nginx_config.py
nginx -g 'daemon off;'
