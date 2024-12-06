# How to set up NGINX and Prometheus on Mac for development

This doc will describe how to set up a temporary Prometheus and NGINX instance to develop Tinyweather against. Prometheus is used as a timeseries database, and NGINX is a proxy used to add HTTP headers to the Prometheus HTTP request. If this doesn't mean anything to you, Tinyweather uses HTTP headers to request data from certain sensors. Here is an example

```bash
curl localhost:8081/metrics -H "sensor:RainTotalAcc"  
```

The request above will get the total rain accumulation from the rain gauge. Prometheus doesn't support custom HTTP headers (sigh), so we need to put a proxy in front of it. I don't really like this, but here we are.

## Prometheus

First, download Prometheus from your package manager. Likely you will be using brew. To start a temporary Prometheus instance, you can run the following

```bash
/opt/homebrew/opt/prometheus/bin/prometheus_brew_services
```

You'll then want to update the prometheus.yml file to target the tinyweather-proxy, in the case of local development the config will look something like this 

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
    - targets: ["localhost:8081"]
```

## NGINX

Now you need to set up the NGINX proxy. You can start a temporary instance by running the following

```bash
/opt/homebrew/opt/nginx/bin/nginx -g daemon\ off\;
```

it defaults by listening on port 8080, so you need to go into `/opt/homebrew/etc/nginx/nginx.conf` and update that port to 8082. nginx will load all files in /opt/homebrew/etc/nginx/servers/.

