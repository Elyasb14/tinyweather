# To Run a Proxy

You will need to install the following dependencies

- zig version 0.13.0 [link](https://ziglang.org/learn/getting-started/)
- nginx [link](https://nginx.org/)
- go version 1.17 or greater [link](https://go.dev/doc/install)
- npm version 7 or greater

## installing Prometheus

There is a script, `scripts/bootstrap_prometheus.sh`. This builds prometheus from source (warning this takes a while) and starts prometheus as a systemd service.

## Installing the proxy

There is a sript `scripts/bootstrap_proxy.sh`. This will start `tinyweather-proxy` as a systemd service. 

## NGINX proxies

For prometheus to be able to talk to nodes through the proxy, we need to be able to pass custom headers to the proxy. Unfortunately Prometheus doesn't support this, so we need to have nginx between prometheus and the proxy. There is a script that will install a shell version of what you want here, it is located at `./scripts/bootstrap_nginx.sh`. You should read that script and make sure the configs make sense for what you are trying to do.  
