# Tinyweather Development Setup: Prometheus and Nginx

## Goal
Set up Prometheus and Nginx to handle custom sensor headers for local development.

## Prometheus Setup
1. Install via Homebrew
2. Start Prometheus: 
   ```bash
   /opt/homebrew/opt/prometheus/bin/prometheus_brew_services
   ```
3. Edit `/opt/homebrew/etc/prometheus.yml`:
   ```yaml
   global:
     scrape_interval: 15s
   scrape_configs:
     - job_name: "prometheus"
       static_configs:
       - targets: ["localhost:8081"]
   ```

## Nginx Setup
1. Install via Homebrew
2. Start Nginx: 
   ```bash
   /opt/homebrew/opt/nginx/bin/nginx -g daemon\ off\;
   ```
3. Configure `/opt/homebrew/etc/nginx/nginx.conf` with:
   ```nginx
    worker_processes  1;

    events {
        worker_connections  1024;
    }

    http {
        include       mime.types;
        default_type  application/octet-stream;
        
        sendfile        on;
        keepalive_timeout  65;

        server {
            listen 8082;
            
            location /{
                proxy_pass http://localhost:8081;
                proxy_set_header sensor "Temp";
            }

            error_page   500 502 503 504  /50x.html;
            location = /50x.html {
                root   html;
            }
        }

        include servers/*;
    }
   ```

## Test
```bash
curl localhost:8081/metrics -H "sensor:RainTotalAcc"
```

This setup lets you add custom headers to Prometheus requests.
