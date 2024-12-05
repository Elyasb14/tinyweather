# How to set up NGINX and Prometheus on Mac for development

This doc will describe how to set up a temporary Prometheus and NGINX instance to develop Tinyweather against.

## Prometheus

First, download Prometheus from your package manager. Likely you will be using brew. To start a temporary Prometheus instance, you can run the following

```bash
/opt/homebrew/opt/prometheus/bin/prometheus_brew_services
```

## NGINX

Docroot is: /opt/homebrew/var/www

The default port has been set in /opt/homebrew/etc/nginx/nginx.conf to 8080 so that
nginx can run without sudo.

nginx will load all files in /opt/homebrew/etc/nginx/servers/.

To start nginx now and restart at login:
  brew services start nginx
Or, if you don't want/need a background service you can just run:
  /opt/homebrew/opt/nginx/bin/nginx -g daemon\ off\;
