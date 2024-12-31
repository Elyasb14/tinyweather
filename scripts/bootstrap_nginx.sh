#! /bin/bash

# WARNING: this is only tested on ubuntu linux with systemd. This is tightly coupled with tinyweather. Don't expect this to 'just work' 
#
nginx -v

if [[ -f /etc/nginx/nginx.conf ]]; then
  rm /etc/nginx/nginx.conf
fi

touch /etc/nginx/nginx.conf

echo "
user www-data;                  # User to run NGINX
worker_processes auto;       # Automatically determine the number of worker processes
pid /var/run/nginx.pid;      # Location of the PID file

events {
    worker_connections 1024; # Maximum number of simultaneous connections
}

http {
    # Basic settings
    include /etc/nginx/mime.types;  # File extensions and their MIME types
    default_type application/octet-stream;
    sendfile on;                   # Enable efficient file transfers
    keepalive_timeout 65;          # Time a connection stays open
    server_tokens off;             # Disable NGINX version in error pages

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Include server configurations
    include /etc/nginx/sites-enabled/*;
}" >> /etc/nginx/nginx.conf

if [[ -d /etc/nginx/sites-available ]]; then
  rm -rf /etc/nginx/sites-available
fi

if [[ -d /etc/nginx/sites-enabled ]]; then
  rm -rf /etc/nginx/sites-enabled
fi

mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

touch /etc/nginx/sites-available/node-127001

echo "
server {
    listen 8082;

    location /{
        proxy_pass http://localhost:8081;
        proxy_set_header sensor "Temp";
        proxy_set_header sensor "RainTotalAcc";
        proxy_set_header address "127.0.0.1";
        proxy_set_header port 8080;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}" >> /etc/sites-available/node-127001

ln -s /etc/nginx/sites-available/node-127001 /etc/nginx/sites-enabled/

nginx -t
systemctl reload nginx
systemctl status nginx
