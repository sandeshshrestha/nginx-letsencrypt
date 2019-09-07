#!/usr/bin/env sh

certbot renew --post-hook "nginx -s reload"
