# How To Run a Proxy

You will need to install the following dependencies

- zig version 0.13.0 [link](https://ziglang.org/learn/getting-started/)
- nginx [link](https://nginx.org/)
- go version 1.17 or greater [link](https://go.dev/doc/install)
- npm version 7 or greater

## installing Prometheus

There is a script, `scripts/bootstrap_prometheus.sh`. This starts prometheus as a systemd service.

## Installing the proxy

There is a sript `scripts/bootstrap_proxy.sh`. This will start `tinyweather-proxy` as a systemd service. 

## NGINX proxies

For prometheus to be able to talk to nodes through the proxy, we need to be able to pass custom headers to the proxy. Unfortunately Prometheus doesn't support this, so we need to have nginx between prometheus and the proxy. The config for your nginx servers should look something like this:

```nginx
server {
    listen 8082;

    location /{
        proxy_pass http://localhost:8081;
        proxy_set_header sensor "Temp";
        proxy_set_header sensor "RainTotalAcc"
        proxy_set_header address "127.0.0.1";
        proxy_set_header port 8080;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
```

