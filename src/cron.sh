#!/usr/bin/env bash

certbot renew --post-hook "service nginx restart"
