#!/usr/bin/env bash

# Replace Enviromental variables in nginx.conf.tmpl
VARS='$NGINX_TRUSTED_IP:$NGINX_PORT'
envsubst "$VARS" < /etc/nginx/nginx.conf.tmpl > /etc/nginx/nginx.conf

# Start nginx
exec nginx -g 'daemon off;'
