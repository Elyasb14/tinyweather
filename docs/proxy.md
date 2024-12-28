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

For prometheus to be able to talk to nodes through the proxy, we need to be able to pass custom headers to `tinyweather-proxy`. Unfortunately Prometheus doesn't support this, so we need to have nginx between prometheus and `tinyweather-proxy`. This is how you should configure your nginx servers.



