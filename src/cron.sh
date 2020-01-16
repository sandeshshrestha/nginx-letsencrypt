#!/usr/bin/env sh

certbot renew --post-hook "sh /etc/init.d/nginx reload" >> /app/src/cron-log.txt 2>&1